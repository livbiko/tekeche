# Tekeche — Low-Level Design (LLD)
## BikoFW-SRX ↔ Oracle Cloud Infrastructure Site-to-Site VPN

**Version:** 1.0
**Date:** 2026-07-09
**Status:** ✅ LIVE — both tunnels UP
**Reference:** `ops/oci/HLD.md` (primary hybrid infra HLD), `ops/oci/LLD-MX68-VPN.md` (related, separate tunnel), `ops/MAINTENANCE_LOG.md` (2026-07-08/09 entries), memory `project_srx_oci_vpn.md`

---

## 1. Overview

RRAS's tunnel (the only working OCI↔on-prem path) was decommissioned 2026-07-08. The Meraki MX68 tunnel ([[LLD-MX68-VPN.md]]) never worked (ESP never establishes, blocked on Meraki TAC). This project builds a **new, independent** site-to-site VPN terminating directly on **BikoFW-SRX** (Juniper SRX300) itself, covering `192.168.1.0/24` (the `dmz` zone, where the production NLB VIP `192.168.1.100` lives).

**Why SRX directly, not through MX68**: BikoFW-SRX's own outbound NAT resolves to a private IP (`192.168.128.2`) requiring a hop through MX68 to reach the internet — same shared-IP concern as RRAS had, plus an untested MX68-passthrough dependency. Instead, BikoFW-SRX gets its **own direct path** via a Hub Manager port-forward, since Hub Manager (`192.168.1.254`) and SRX's `irb.50` (dmz zone, `192.168.1.1/24`) are on the same subnet.

**Goals**
- Give `192.168.1.0/24` a working, redundant (2-tunnel) path to OCI's private network (`10.0.0.0/16`)
- Match Oracle's official SRX configuration template crypto defaults for maximum compatibility/support
- Zero impact to existing SRX features (`wizard_dyn_vpn` on `st0.0`, existing dmz policies)

---

## 2. Addressing Reference

| Name | Value |
|---|---|
| Shared public IP (site NAT egress) | `81.130.238.41` |
| BT Hub Manager (ISP router) | `192.168.1.254` |
| dmz zone / Segment A | `192.168.1.0/24` — BikoFW-SRX `irb.50` = `.1`, NLB VIP = `.100` |
| BikoFW-SRX management | `192.168.128.2` (SSH: user `malindo`, password given ad hoc each session — not persisted) |
| OCI private network (advertised to SRX) | `10.0.0.0/16` |
| OCI tunnel endpoint 1 | `140.238.94.206` (st0.1) |
| OCI tunnel endpoint 2 | `152.67.132.126` (st0.2) |
| OCI compartment | `tekeche-pub` — `ocid1.compartment.oc1..aaaaaaaamowm6hhwtteb7uf3c6pytddjjh4xu7thlz5uxyk7ckjbyv6upa5a` |
| OCI region | `uk-london-1` |
| `oci_core_cpe.srx` | `ocid1.cpe.oc1.uk-london-1.aaaaaaaa53t6g5xafguw2s4up54svgwa6umqwz5qasl3c3wax65rmi2rs4pa` |
| `oci_core_ipsec.srx` | `ocid1.ipsecconnection.oc1.uk-london-1.amaaaaaaoz32urqaoolsbcgfc54gcu3htkk4o44xsgticilpyong6jv3nfxa` |
| tunnel1 OCID | `ocid1.ipsectunnel.oc1.uk-london-1.aaaaaaaax3rt2hjxcsxp5bdif6643xydi4sigqsq5pt32ctw2ol5iuxrdnpa` |
| tunnel2 OCID | `ocid1.ipsectunnel.oc1.uk-london-1.aaaaaaaaz44z7qhpppekwjmuf5lri4ahdcmpizburkuj2zhnme6jw2fy6via` |

---

## 3. OCI-Side Integration — Step by Step

### Step 1 — Prerequisite: Hub Manager port-forward (manual, no API access)

User added on the BT Hub Manager: UDP `500` and UDP `4500`, both forwarded to `192.168.1.1` (BikoFW-SRX's `irb.50`).

### Step 2 — Terraform: CPE + IPSec connection

New file `ops/oci/vpn_srx.tf`:

```hcl
resource "oci_core_cpe" "srx" {
  compartment_id = var.compartment_id
  ip_address     = var.onprem_public_ip
  display_name   = "${var.project_name}-srx-cpe"
}

resource "oci_core_ipsec" "srx" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.srx.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-srx-ipsec"
  static_routes  = [var.onprem_cidr]

  # SRX is behind NAT and sends its dmz-zone IP as its IKE identity, not the
  # public IP -- same pattern RRAS previously needed.
  cpe_local_identifier      = var.srx_local_identifier
  cpe_local_identifier_type = "IP_ADDRESS"
}
```

New variables in `ops/oci/variables.tf`:

```hcl
variable "srx_local_identifier" {
  default     = "192.168.1.1"
  description = "BikoFW-SRX's irb.50 (dmz zone) IP -- sent as its IKE local identity since it's behind NAT"
}
variable "srx_vpn_shared_secret" {
  default     = ""
  sensitive   = true
  description = "Pre-shared key for the BikoFW-SRX <-> OCI IPSec connection"
}
```

`terraform.tfvars` (gitignored):
```
srx_vpn_shared_secret = "<generated via PowerShell alphanumeric-only, 32 chars>"
```
Generation command (alphanumeric only — OCI's tunnel API rejects `+/=`):
```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

Apply:
```bash
terraform apply -target=oci_core_cpe.srx -target=oci_core_ipsec.srx
```

**Gotcha hit**: `cpe_local_identifier`/`cpe_local_identifier_type` are NOT valid on `oci_core_cpe` — Terraform errors "Unsupported argument". They belong on `oci_core_ipsec` instead (as shown above).

### Step 3 — Terraform: tunnel management (final, post-rebuild version)

New file `ops/oci/vpn_srx_tunnels.tf`:

```hcl
data "oci_core_ipsec_connection_tunnels" "srx" {
  ipsec_id   = oci_core_ipsec.srx.id
  depends_on = [oci_core_ipsec.srx]
}

resource "oci_core_ipsec_connection_tunnel_management" "srx_tunnel1" {
  ipsec_id  = oci_core_ipsec.srx.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.srx.ip_sec_connection_tunnels[0].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "srx-tunnel-1"
  shared_secret = var.srx_vpn_shared_secret

  # Matches Oracle's official SRX configuration template defaults
  dpd_config {
    dpd_mode           = "INITIATE_AND_RESPOND"
    dpd_timeout_in_sec = 20
  }

  phase_one_details {
    is_custom_phase_one_config      = true
    custom_authentication_algorithm = "SHA2_384"
    custom_encryption_algorithm     = "AES_256_CBC"
    custom_dh_group                 = "GROUP5"
    lifetime                        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    custom_authentication_algorithm = "HMAC_SHA1_128"
    custom_encryption_algorithm     = "AES_256_CBC"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP5"
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "srx_tunnel2" {
  ipsec_id  = oci_core_ipsec.srx.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.srx.ip_sec_connection_tunnels[1].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "srx-tunnel-2"
  shared_secret = var.srx_vpn_shared_secret

  dpd_config {
    dpd_mode           = "INITIATE_AND_RESPOND"
    dpd_timeout_in_sec = 20
  }

  phase_one_details {
    is_custom_phase_one_config      = true
    custom_authentication_algorithm = "SHA2_384"
    custom_encryption_algorithm     = "AES_256_CBC"
    custom_dh_group                 = "GROUP5"
    lifetime                        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    custom_authentication_algorithm = "HMAC_SHA1_128"
    custom_encryption_algorithm     = "AES_256_CBC"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP5"
  }
}
```

No `encryption_domain_config` block — deliberate. This is a Junos route-based VPN (`st0` interfaces), which naturally proposes wildcard-ish traffic selectors matching OCI's default, unlike Meraki's forced policy-based narrow selectors in [[LLD-MX68-VPN.md]].

Apply:
```bash
terraform apply -target=oci_core_ipsec_connection_tunnel_management.srx_tunnel1 \
                 -target=oci_core_ipsec_connection_tunnel_management.srx_tunnel2
```

Retrieve real tunnel endpoint IPs after apply:
```bash
terraform state show oci_core_ipsec_connection_tunnel_management.srx_tunnel1 | grep vpn_ip
terraform state show oci_core_ipsec_connection_tunnel_management.srx_tunnel2 | grep vpn_ip
```

**Gotcha — first apply used weaker crypto**: the *initial* apply (before the Oracle-template rebuild) used `SHA2_256`/`GROUP14`/`HMAC_SHA2_256_128`. Tunnel2 came up fine on that crypto; **tunnel1 never established at all**, for unexplained reasons (routing and reachability were both confirmed correct). Rebuilding to the values shown above (Oracle's own template defaults) fixed tunnel1 as a side effect — root cause of the original stall was never conclusively identified.

**Gotcha — `dpd_mode`/`dpd_timeout_in_sec`**: not settable as top-level attributes on `oci_core_ipsec_connection_tunnel_management` — Terraform errors "unconfigurable attribute". Must use the nested `dpd_config { }` block as shown.

**Verified via `terraform plan`**: changing `phase_one_details`/`phase_two_details`/`dpd_config` on an *existing* tunnel resource is an **in-place update** (`0 to add, 2 to change, 0 to destroy`) — does not recreate the CPE/IPSec connection/tunnels.

### Step 4 — Validate on OCI side

```bash
oci network ip-sec-tunnel list --ipsc-id ocid1.ipsecconnection.oc1.uk-london-1.amaaaaaaoz32urqaoolsbcgfc54gcu3htkk4o44xsgticilpyong6jv3nfxa \
  --query "data[].{id:id,status:status,\"cpe-ip\":\"cpe-ip\",\"vpn-ip\":\"vpn-ip\"}" --output table
```
Expected: both rows `status: UP`.

---

## 4. SRX-Side Integration — Step by Step

Connection: `plink.exe -ssh -batch -hostkey "SHA256:T9bgpvEI31VwSeQEyn+4kyMtQLJ/pemyfzKx982Ad4A" -pw '<password>' malindo@192.168.128.2 "<command>"` (plink from Chocolatey — OpenSSH has no non-interactive password option available on this host).

### Step 1 — Device-side recovery point (every change, before touching anything)

```
request system configuration rescue save
show configuration | display set | no-more     # save output locally as a text backup
```

### Step 2 — Check for stray uncommitted edits (this device uses shared, not private, candidate config)

```
configure
show | compare
exit
```
Must be clean (no diff) before staging anything new — a real gotcha on this device, confirmed multiple times this session.

### Step 3 — Stage the config (final, post-rebuild version — includes Oracle template crypto + reliability features)

```
configure

# Zone fix — dmz didn't accept inbound IKE at all before this
set security zones security-zone dmz host-inbound-traffic system-services ike
set security zones security-zone dmz host-inbound-traffic system-services tcp-encap

# IKE Phase 1 (Oracle template defaults: SHA-384/Group5)
set security ike proposal IKE-PROP-OCI authentication-method pre-shared-keys
set security ike proposal IKE-PROP-OCI dh-group group5
set security ike proposal IKE-PROP-OCI authentication-algorithm sha-384
set security ike proposal IKE-PROP-OCI encryption-algorithm aes-256-cbc
set security ike proposal IKE-PROP-OCI lifetime-seconds 28800

set security ike policy IKE-POL-OCI mode main
set security ike policy IKE-POL-OCI proposals IKE-PROP-OCI
set security ike policy IKE-POL-OCI pre-shared-key ascii-text "<shared secret>"

set security ike gateway GW-OCI-TUNNEL1 ike-policy IKE-POL-OCI
set security ike gateway GW-OCI-TUNNEL1 address 140.238.94.206
set security ike gateway GW-OCI-TUNNEL1 local-identity inet 192.168.1.1
set security ike gateway GW-OCI-TUNNEL1 external-interface irb.50
set security ike gateway GW-OCI-TUNNEL1 version v2-only
set security ike gateway GW-OCI-TUNNEL1 dead-peer-detection

set security ike gateway GW-OCI-TUNNEL2 ike-policy IKE-POL-OCI
set security ike gateway GW-OCI-TUNNEL2 address 152.67.132.126
set security ike gateway GW-OCI-TUNNEL2 local-identity inet 192.168.1.1
set security ike gateway GW-OCI-TUNNEL2 external-interface irb.50
set security ike gateway GW-OCI-TUNNEL2 version v2-only
set security ike gateway GW-OCI-TUNNEL2 dead-peer-detection

# IPsec Phase 2 (Oracle template defaults: HMAC-SHA1-96/Group5)
set security ipsec proposal IPSEC-PROP-OCI protocol esp
set security ipsec proposal IPSEC-PROP-OCI authentication-algorithm hmac-sha1-96
set security ipsec proposal IPSEC-PROP-OCI encryption-algorithm aes-256-cbc
set security ipsec proposal IPSEC-PROP-OCI lifetime-seconds 3600

set security ipsec policy IPSEC-POL-OCI perfect-forward-secrecy keys group5
set security ipsec policy IPSEC-POL-OCI proposals IPSEC-PROP-OCI

set security ipsec vpn-monitor-options

set security ipsec vpn VPN-OCI-TUNNEL1 ike gateway GW-OCI-TUNNEL1
set security ipsec vpn VPN-OCI-TUNNEL1 ike ipsec-policy IPSEC-POL-OCI
set security ipsec vpn VPN-OCI-TUNNEL1 bind-interface st0.1
set security ipsec vpn VPN-OCI-TUNNEL1 establish-tunnels immediately
set security ipsec vpn VPN-OCI-TUNNEL1 vpn-monitor
set security ipsec vpn VPN-OCI-TUNNEL1 df-bit clear

set security ipsec vpn VPN-OCI-TUNNEL2 ike gateway GW-OCI-TUNNEL2
set security ipsec vpn VPN-OCI-TUNNEL2 ike ipsec-policy IPSEC-POL-OCI
set security ipsec vpn VPN-OCI-TUNNEL2 bind-interface st0.2
set security ipsec vpn VPN-OCI-TUNNEL2 establish-tunnels immediately
set security ipsec vpn VPN-OCI-TUNNEL2 vpn-monitor
set security ipsec vpn VPN-OCI-TUNNEL2 df-bit clear

# Tunnel interfaces — st0.0 already used by wizard_dyn_vpn (unrelated), new units to avoid touching it
set interfaces st0 unit 1 family inet
set interfaces st0 unit 2 family inet

# Zone membership (reuse existing VPN zone)
set security zones security-zone VPN interfaces st0.1
set security zones security-zone VPN interfaces st0.2

# Security policies: dmz <-> VPN, both directions
set security policies from-zone dmz to-zone VPN policy DMZ-TO-OCI match source-address any
set security policies from-zone dmz to-zone VPN policy DMZ-TO-OCI match destination-address any
set security policies from-zone dmz to-zone VPN policy DMZ-TO-OCI match application any
set security policies from-zone dmz to-zone VPN policy DMZ-TO-OCI then permit

set security policies from-zone VPN to-zone dmz policy OCI-TO-DMZ match source-address any
set security policies from-zone VPN to-zone dmz policy OCI-TO-DMZ match destination-address any
set security policies from-zone VPN to-zone dmz policy OCI-TO-DMZ match application any
set security policies from-zone VPN to-zone dmz policy OCI-TO-DMZ then permit

# Routing: OCI's VCN, primary via tunnel1, backup via tunnel2
set routing-options static route 10.0.0.0/16 next-hop st0.1
set routing-options static route 10.0.0.0/16 qualified-next-hop st0.2 preference 20

# Reliability: MSS clamp (Oracle template)
set security flow tcp-mss ipsec-vpn mss 1387
```

### Step 4 — Critical fix discovered mid-deployment: outbound routing gap

`external-interface irb.50` on an IKE gateway only sets IKE *identity* — it does **not** control the actual outbound route. SRX's default route (`0.0.0.0/0`) goes via `ge-0/0/0.0` → MX68 (`192.168.128.1`), **not** via Hub Manager. Without a fix, SRX tries to reach OCI's tunnel endpoints through MX68 instead of the intended direct path. Fix (still inside `configure`):

```
set routing-options static route 140.238.94.206/32 next-hop 192.168.1.254
set routing-options static route 152.67.132.126/32 next-hop 192.168.1.254
```
Purely additive — doesn't touch the default route. Confirmed Hub Manager (`192.168.1.254`) reachable first: `ping 192.168.1.254 source 192.168.1.1`.

### Step 5 — Review, then commit with a safety net

```
show | compare
commit confirmed 5
```
Then validate (see §5) before finalizing:
```
commit
```
If anything looks wrong instead: do nothing — `commit confirmed` auto-reverts after 5 minutes on its own.

### Step 6 — Failed experiment, for the record: static ARP is NOT viable on Junos

While investigating a *separate* downstream issue (see §6), attempted:
```
set interfaces irb unit 50 family inet address 192.168.1.1/24 arp 192.168.1.100 mac 03:bf:c0:a8:01:64
```
**Junos rejects this outright**: `error: Invalid unicast mac address`. Junos's static-ARP command validates the MAC must be unicast — the NLB cluster's MAC is multicast. This is a hard platform restriction, not a syntax issue. Discarded cleanly with `rollback 0` before committing. Don't retry this approach on Junos.

---

## 5. Validation Commands (both sides)

```
# SRX
show security ike security-associations
show security ipsec security-associations
show interfaces st0 terse
show security flow session destination-prefix <target-ip>   # trace a specific flow end-to-end

# OCI
oci network ip-sec-tunnel list --ipsc-id <ipsec-connection-ocid> --query "data[].{status:status,\"vpn-ip\":\"vpn-ip\"}" --output table
oci lb backend-health get --load-balancer-id <lb-ocid> --backend-set-name main-backends --backend-name "192.168.1.100:443"
```

Result as of 2026-07-09: both IKE SAs UP, both IPsec SAs active, `st0.1`/`st0.2` up/up, OCI reports both tunnels `UP`. `wizard_dyn_vpn`/`st0.0` and pre-existing dmz policies confirmed untouched throughout.

---

## 6. Known Follow-Up — NOT part of this VPN build, discovered because of it

Getting the tunnel up exposed a **pre-existing, unrelated production issue**: the on-prem NLB cluster (`192.168.1.100`, nodes `BikoDC`/`BikoDC1`) runs in `MULTICAST` operation mode, which is unreachable from any *routed* path (routers can't forward to a multicast MAC via normal ARP). This was invisible until this VPN made OCI-to-on-prem routed traffic possible for the first time — and is the likely cause of multi-user login failures (OCI's LB has been failing over all public traffic to the OCI standby, whose MongoDB isn't in the replica set).

Full detail, fix attempts, and next steps: memory `project_nlb_multicast_oci_routing.md`, `ops/MAINTENANCE_LOG.md` (2026-07-09 14:06 entry). **Not resolved** — a unicast-mode fix attempt failed on an RPC error between the two NLB nodes, unrelated to this VPN work.

---

## 7. Change Log

| Date | Change | Commit |
|---|---|---|
| 2026-07-08 | OCI side built: CPE, IPSec connection, both tunnels (initial crypto: SHA2_256/GROUP14) | `1e2988d` |
| 2026-07-09 | SRX config applied; discovered + fixed outbound routing gap (Hub Manager static routes) | (device config, not git) |
| 2026-07-09 | OCI tunnel crypto rebuilt to Oracle template defaults (SHA2_384/GROUP5/HMAC_SHA1_128) + DPD | `bfd1f94` |
| 2026-07-09 | SRX crypto rebuilt to match + DPD/vpn-monitor/df-bit-clear/MSS-clamp | (device config, not git) |
| 2026-07-09 | Recovery points: `2026-07-08_19-46-55_before-bikofw-srx-oci-vpn-config-apply`, `2026-07-09_13-37-49_before-rebuilding-bikofw-srx-oci-vpn-cry`, `2026-07-09_15-44-50_before-adding-static-arp-entry-on-bikofw`, `2026-07-09_15-55-13_before-switching-tekechecluster-nlb-from` | — |
