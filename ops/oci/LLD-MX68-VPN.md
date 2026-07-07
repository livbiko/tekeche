# Tekeche — Low-Level Design (LLD)
## Meraki MX68 ↔ Oracle Cloud Infrastructure Site-to-Site VPN

**Version:** 1.0
**Date:** 2026-07-07
**Reference HLD:** `ops/oci/HLD-MX68-VPN.md`

---

## 1. Addressing Reference

| Name | Value |
|---|---|
| Shared public IP (both segments' NAT egress) | `81.130.238.41` |
| BT Hub Manager (ISP router) | `192.168.1.254` |
| Segment A | `192.168.1.0/24` — BIKODC `.100`, MX68 WAN1 `.214` |
| BikoFW-SRX | `192.168.128.2` (routes between Segment A and Segment B) |
| Segment B / MX68 LAN | `192.168.128.0/24`, appliance IP `.1`, Single LAN mode |
| OCI private network (advertised to MX68) | `10.0.0.0/16` |
| OCI tunnel endpoint 1 | `152.67.132.126` |
| OCI tunnel endpoint 2 | `152.67.138.186` |
| Meraki org / network | `Livbiko` (`1685535`) / `LivbikoHQ` (`L_4005951868546056623`) |
| MX68 device serial | `Q2NY-MC4Z-JGQR` (model MX68CW-WW) |
| OCI compartment | `tekeche-pub` — `ocid1.compartment.oc1..aaaaaaaamowm6hhwtteb7uf3c6pytddjjh4xu7thlz5uxyk7ckjbyv6upa5a` |
| OCI region | `uk-london-1` |

---

## 2. OCI-Side Configuration

### 2.1 Terraform files

`ops/oci/vpn_mx68.tf` — CPE + IPSec connection:

```hcl
resource "oci_core_cpe" "mx68" {
  compartment_id = var.compartment_id
  ip_address     = var.mx68_public_ip        # 81.130.238.41
  display_name   = "${var.project_name}-mx68-cpe"
}

resource "oci_core_ipsec" "mx68" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.mx68.id
  drg_id         = oci_core_drg.drg.id        # same DRG as the RRAS tunnel
  display_name   = "${var.project_name}-mx68-ipsec"
  static_routes  = [var.mx68_lan_cidr]        # 192.168.128.0/24
}
```

`ops/oci/vpn_mx68_tunnels.tf` — tunnel management (both tunnels identical apart from `display_name`/`tunnel_id`):

```hcl
resource "oci_core_ipsec_connection_tunnel_management" "mx68_tunnel1" {
  routing       = "STATIC"
  ike_version   = "V2"
  shared_secret = var.mx68_vpn_shared_secret

  phase_one_details {
    is_custom_phase_one_config      = true
    custom_authentication_algorithm = "SHA2_256"
    custom_encryption_algorithm     = "AES_256_CBC"
    custom_dh_group                 = "GROUP14"
    lifetime                        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    custom_authentication_algorithm = "HMAC_SHA2_256_128"
    custom_encryption_algorithm     = "AES_256_CBC"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP14"
  }

  encryption_domain_config {
    oracle_traffic_selector = ["10.0.0.0/16"]
    cpe_traffic_selector    = ["192.168.128.0/24"]
  }
}
```

`variables.tf` additions: `mx68_public_ip`, `mx68_lan_cidr` (`192.168.128.0/24`), `mx68_vpn_shared_secret` (sensitive, in gitignored `terraform.tfvars`).

`networking.tf` additions: `192.168.128.0/24` → DRG route rule on both `oci_core_route_table.public` and `.private`; a broad `ingress_security_rules { protocol = "all", source = var.mx68_lan_cidr }` on `oci_core_security_list.private` (intentionally unscoped per original "whole private network" requirement).

### 2.2 Resource identifiers

| Resource | OCID / value |
|---|---|
| IPSec connection | `ocid1.ipsecconnection.oc1.uk-london-1.amaaaaaaoz32urqav3wtoz7ikvrztlf4pddnjsastfxo7sj3up5exzt5yxiq` |
| Tunnel 1 | `ocid1.ipsectunnel.oc1.uk-london-1.aaaaaaaagubwd4a6sl2h2dhrd6bvaiqiixtfq6psl35bwsmkge5r5c6kui3a` |
| Tunnel 2 | `ocid1.ipsectunnel.oc1.uk-london-1.aaaaaaaaigtub5ieat4djmlb6l3bsmmfsspjlhhc5evr2dsxkzsgnt2gfriq` |
| Sibling RRAS connection (for comparison) | `ocid1.ipsecconnection.oc1.uk-london-1.amaaaaaaoz32urqacizbzegbq3hgnmikweghmoa773qskfypvneoestudfyq` |

### 2.3 Why `encryption_domain_config` is set explicitly

Meraki's non-Meraki VPN peers are always **policy-based** (`isRouteBased: false` — see §3), so MX68 proposes narrow Phase 2 traffic selectors (`192.168.128.0/24 ↔ 10.0.0.0/16`) rather than a wildcard. OCI defaults to `0.0.0.0/0 ↔ 0.0.0.0/0` when this block is omitted (this is fine for RRAS, which negotiates as route-based/wildcard). This block was added on 2026-07-07 to match Meraki's exact proposal — applied cleanly via a `terraform plan -target=...` scoped to just these two resources (confirmed zero impact to the RRAS connection), but **did not resolve** the ESP issue (see §5).

---

## 3. Meraki-Side Configuration

Applied via `PUT /organizations/1685535/appliance/vpn/thirdPartyVPNPeers`:

```json
{
  "peers": [
    {
      "name": "OCI-MX68-Tunnel1",
      "publicIp": "152.67.132.126",
      "ikeVersion": "2",
      "isRouteBased": false,
      "privateSubnets": ["10.0.0.0/16"],
      "ipsecPolicies": {
        "ikeCipherAlgo": ["aes256"], "ikeAuthAlgo": ["sha256"],
        "ikePrfAlgo": ["default"], "ikeDiffieHellmanGroup": ["group14"],
        "ikeLifetime": 28800,
        "childCipherAlgo": ["aes256"], "childAuthAlgo": ["sha256"],
        "childPfsGroup": ["group14"], "childLifetime": 3600
      }
    },
    { "name": "OCI-MX68-Tunnel2", "publicIp": "152.67.138.186", "...": "identical policy" }
  ]
}
```

Local subnet `192.168.128.0/24` has `useVpn: true` in the network's `siteToSiteVpn` config.

**Crypto parity confirmed against OCI** (both phases): cipher AES-256, auth SHA-256/HMAC_SHA2_256_128, DH group 14, PFS enabled, lifetimes 28800s (Phase 1) / 3600s (Phase 2) — no mismatch on either side.

---

## 4. BikoFW-SRX Configuration Change

Applied 2026-07-06 (HIGH RISK, approved, `commit confirmed 10` then finalized):

```
set applications application app-udp-4500 protocol udp
set applications application app-udp-4500 destination-port 4500
set applications application-set as-ipsec-natt application junos-ike
set applications application-set as-ipsec-natt application app-udp-4500

set security policies from-zone untrust to-zone dmz policy PF-IPSEC-500-4500 match source-address any
set security policies from-zone untrust to-zone dmz policy PF-IPSEC-500-4500 match destination-address server-1
set security policies from-zone untrust to-zone dmz policy PF-IPSEC-500-4500 match application as-ipsec-natt
set security policies from-zone untrust to-zone dmz policy PF-IPSEC-500-4500 then permit

delete security policies from-zone untrust to-zone dmz policy server-access
```

`server-access` was a pre-existing broad `any/any/any` permit to the same destination (`server-1` = `192.168.1.100`) — removed since it made the new narrower rule redundant, after confirming no other narrower policy depended on it (HTTPS is separately covered by `idp-app-policy-4`; BIKODC's own outbound VPN traffic by `dmz-to-untrust`'s `junos-udp-any`).

**Access**: SSH to `192.168.128.2`, user `malindo` (password not stored — see project memory), via `plink.exe` (OpenSSH's `ssh` has no non-interactive password flag available on this host). Host key: `SHA256:T9bgpvEI31VwSeQEyn+4kyMtQLJ/pemyfzKx982Ad4A`. Device: Junos SRX300, hostname `BikoFW`, Junos `19.4R3-S1.3`.

**⚠️ Shared candidate config**: this SRX does not use per-session private edit mode — always run `show | compare` before committing anything, to catch any other engineer's uncommitted changes riding along with yours. (One such stray edit, an incomplete `INTERNET-OUT` policy, was found and discarded during this change.)

---

## 5. Diagnostic Findings (all confirmed 2026-07-06/07)

| Check | Method | Result |
|---|---|---|
| Network path MX68 → OCI tunnel endpoint | Meraki live-tools ping from the device itself | 5/5 received, 0% loss, ~4-5ms — path is clean |
| BT Hub Manager port-forwarding | Screenshot of forwarding rules table | UDP 500/4500 forward only to `192.168.1.100` (BIKODC); no rule for MX68 |
| BikoFW-SRX position in the traffic path | SSH inspection (ARP, live sessions, interfaces) | Not in the direct internet↔`192.168.1.0/24` path; routes between the two on-prem segments only |
| Crypto/algorithm parity | Compared Meraki `ipsecPolicies` vs OCI `phase-one/two-details` | Exact match both phases |
| Traffic selector / encryption domain | Compared Meraki (policy-based, narrow) vs OCI (was wildcard default) | Mismatch found and fixed (§2.3) — **no change in outcome** |
| OCI tunnel error-detail API | `GetIpSecConnectionTunnelError` | Returns `"IKE SA not established"` — **contradicts** live `is-ike-established: true` at the same moment; treated as a stale/cached error, not trustworthy for live diagnosis |
| VPN registry recompute | Meraki `vpn_registry_change` events | Was stuck since mid-June; MX68 reboot (2026-07-06) fixed it — 2 new events fired, Phase 1 started working immediately after |

**Net conclusion**: reachability, firewall/NAT, crypto, and traffic selectors are all confirmed correct. IKE (Phase 1) is solid on both tunnels. ESP (Phase 2) has never established despite three independent, verified-correct fixes. The remaining unknown is inside Meraki's own IKE/IPsec daemon behavior on the MX68 — not visible via the Dashboard API.

---

## 6. Command/API Reference

```bash
# OCI tunnel status
oci network ip-sec-tunnel list --ipsc-id <connection-ocid>

# OCI tunnel error detail (caution: can be stale, see §5)
oci network ip-sec-connection-tunnel-error-details get-ip-sec-connection-tunnel-error \
  --ipsc-id <connection-ocid> --tunnel-id <tunnel-ocid>

# Find OCI resources across compartments (edits API only searches one compartment at a time)
oci search resource structured-search --query-text "query ipsecconnection resources"

# Meraki: current third-party VPN peers
curl -s "https://api.meraki.com/api/v1/organizations/1685535/appliance/vpn/thirdPartyVPNPeers" \
  -H "Authorization: Bearer $MERAKI_API_KEY"

# Meraki: tunnel reachability
curl -s "https://api.meraki.com/api/v1/organizations/1685535/appliance/vpn/statuses?networkIds[]=L_4005951868546056623" \
  -H "Authorization: Bearer $MERAKI_API_KEY"

# Meraki: live ping test from the MX68 itself
curl -s -X POST "https://api.meraki.com/api/v1/devices/Q2NY-MC4Z-JGQR/liveTools/ping" \
  -H "Authorization: Bearer $MERAKI_API_KEY" -H "Content-Type: application/json" \
  -d '{"target":"152.67.132.126","count":5}'

# BikoFW-SRX (via plink, since OpenSSH ssh has no non-interactive password flag here)
plink.exe -ssh -batch -hostkey "SHA256:T9bgpvEI31VwSeQEyn+4kyMtQLJ/pemyfzKx982Ad4A" \
  -pw '<password>' malindo@192.168.128.2 "<junos command>"
```

Meraki API key is not persisted anywhere — must be supplied fresh each session.
