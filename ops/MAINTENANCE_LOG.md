# Maintenance Log

All maintenance windows and incidents are recorded here.
Format: Date | Type | Duration | Description | Outcome

---

## Template

```
## YYYY-MM-DD HH:MM — [Maintenance/Incident]

- **Type**: Planned maintenance | Unplanned incident | Emergency rollback
- **Duration**: X minutes
- **Risk level**: Low | Medium | High
- **Changes made**: Description
- **Recovery point**: ID of recovery point created before change
- **Outcome**: Success | Partial | Rolled back
- **Downtime**: X minutes
- **Affected**: API | Database | Mobile | All
- **Notes**: Any additional context
```

---

## 2026-06-28 — Initial OPS System Setup

- **Type**: Planned maintenance
- **Duration**: ~30 minutes
- **Risk level**: Low
- **Changes made**: Created backup/recovery/change management system in `ops/`
- **Recovery point**: None (additive only — no existing code modified)
- **Outcome**: Success
- **Downtime**: 0 minutes
- **Notes**: First recovery point should be created before next medium/high risk change

## 2026-07-06 12:00 — BikoFW-SRX firewall policy change (MX68 VPN troubleshooting)

- **Type**: Planned maintenance
- **Duration**: ~10 minutes (staging + commit confirmed 10 + validation + final commit)
- **Risk level**: High (shared production NAT/firewall device, `192.168.1.100`/BIKODC/RRAS tunnels also front this device)
- **Changes made**: On BikoFW-SRX (Junos SRX300, `192.168.128.2`): added application `app-udp-4500`, application-set `as-ipsec-natt` (junos-ike + app-udp-4500), added security policy `PF-IPSEC-500-4500` (`untrust`→`dmz`, dest `server-1`/192.168.1.100, permit), deleted the pre-existing broad `server-access` policy (any/any/any permit to same destination). Also discarded an unrelated, incomplete, pre-existing uncommitted policy (`INTERNET-OUT`, missing mandatory `match`) found sitting in the shared candidate config from another session — confirmed by user not to be theirs before discarding.
- **Recovery point**: Full running config saved locally (`bikofw-srx-config-backup-2026-07-06.txt`, 941 lines) + Junos `request system configuration rescue save` taken on-device. Committed via `commit confirmed 10` (auto-rollback safety net) before finalizing with plain `commit`.
- **Outcome**: Partial — committed successfully, no regression (RRAS/BIKODC tunnels `tekeche-ipsec` stayed UP, IKE+ESP established throughout), but did not fix the actual goal (MX68↔OCI tunnel `tekeche-mx68-ipsec` Phase 2/ESP remained DOWN afterward). Change was kept since it's safe and may still be correct for a path not fully exercised during this test window.
- **Downtime**: 0 minutes (no impact to production RRAS tunnels observed)
- **Affected**: Network/VPN only, no application impact
- **Notes**: Root cause of MX68 tunnel not establishing ESP still unresolved as of this entry — see follow-up entry below and `project_meraki_mx68_vpn.md` memory for full troubleshooting history.

## 2026-07-06 12:25 — OCI MX68 tunnel encryption-domain-config change (MX68 VPN troubleshooting, follow-up)

- **Type**: Planned maintenance
- **Duration**: ~5 minutes (terraform plan/apply + validation)
- **Risk level**: Low-Medium (isolated to 2 not-yet-working MX68 tunnel resources; `terraform plan -target` confirmed zero impact to RRAS/BIKODC resources)
- **Changes made**: Via Terraform (`C:\inetpub\wwwroot\tekeche\ops\oci\vpn_mx68_tunnels.tf`), added `encryption_domain_config` blocks to both `oci_core_ipsec_connection_tunnel_management.mx68_tunnel1`/`mx68_tunnel2` (`oracle_traffic_selector = ["10.0.0.0/16"]`, `cpe_traffic_selector = ["192.168.128.0/24"]`) to match Meraki's policy-based VPN traffic-selector proposal instead of OCI's wildcard default.
- **Recovery point**: Git-tracked Terraform file (revertible); `terraform apply` targeted only the 2 affected resources.
- **Outcome**: Applied successfully (0 added, 2 changed, 0 destroyed) — no regression on RRAS tunnels — but did not fix MX68's Phase 2/ESP either (confirmed DOWN after apply + a Meraki-side `useVpn` toggle nudge, polled ~3.5 minutes with no change).
- **Downtime**: 0 minutes
- **Affected**: Network/VPN only
- **Notes**: MX68↔OCI tunnel (`tekeche-mx68-ipsec`) remains unresolved after 3 independent fix attempts (SRX firewall rule, OCI traffic selectors, plus 2 reboot/toggle nudges) all ruling out crypto mismatch, firewall blocking, and traffic-selector mismatch as the cause. Next step: inspect Meraki's own VPN diagnostic/event log in more detail, or escalate to Meraki support. See `project_meraki_mx68_vpn.md` memory for full details.

## 2026-07-08 — Open AD ports from on-prem to OCI private subnet

- **Type**: Planned maintenance
- **Duration**: ~5 minutes (edit, plan, apply, verify)
- **Risk level**: High (widens security posture into the private subnet with full AD auth protocols — LDAP, Kerberos, SMB — ahead of anything actually using them)
- **Changes made**: Added 11 ingress rules to `oci_core_security_list.private` (`ops/oci/networking.tf`) for DNS (53 TCP+UDP), Kerberos (88 TCP+UDP), W32Time (123 UDP), RPC Endpoint Mapper (135 TCP), LDAP (389 TCP), SMB (445 TCP), LDAPS (636 TCP), Global Catalog (3268/3269 TCP), and the RPC dynamic port range (49152–65535 TCP), all sourced from `192.168.1.0/24` (where the `livbiko.local` domain controllers BIKODC/BIKODC1/BIKODC2 live). Prep work for eventually extending Active Directory reachability into OCI — nothing in OCI listens on these ports yet.
- **Recovery point**: Git-tracked Terraform change (commit `26101c2`), revertible via `terraform apply` after reverting the diff.
- **Outcome**: Success — `terraform plan -target=oci_core_security_list.private` confirmed isolated scope (0 add, 1 change, 0 destroy) before applying; applied via local Terraform (state lives only locally on this machine, no remote backend configured — an OCI Cloud Shell attempt was aborted before running `terraform apply` there specifically because Cloud Shell has no copy of this project's state/tfvars and could have tried to recreate/duplicate the ~36 already-deployed resources). Verified all 11 rules live via `oci network security-list get` post-apply.
- **Downtime**: 0 minutes
- **Affected**: Network/security only, no application impact
- **Notes**: This is prep only — no AD resource actually runs in OCI yet. Also flagged separately (not yet actioned): `BIKODC`'s registered AD IP shows as `169.254.0.36` (APIPA/link-local), likely a stale DNS registration from a secondary NIC — worth fixing independent of this OCI work. See `project_meraki_mx68_vpn.md`-adjacent memory / this session for the broader "connect livbiko.local to OCI" context (extending AD to OCI, eventually consolidating/replacing the RRAS tunnel's role).

## 2026-07-08 — Forward livbiko.local DNS queries from OCI to on-prem DCs

- **Type**: Planned maintenance
- **Duration**: ~15 minutes (two-step apply, one syntax fix, one destination-address-limit fix)
- **Risk level**: High (part of the same AD-extension initiative; additive-only within OCI, no existing resource modified)
- **Changes made**: New file `ops/oci/dns_ad_forwarding.tf` — a DNS resolver endpoint (`is_forwarding = true`) in the private subnet, plus two `FORWARD` rules on the VCN's existing default resolver (managed via `resolver_id` match, no `terraform import` needed) sending `livbiko.local.` queries to BIKODC1 (`192.168.1.102`) and BIKODC2 (`192.168.1.103`) — one rule per DC, since OCI caps `destination_addresses` at 1 per rule. BIKODC itself excluded (its registered AD IP is the stale APIPA address noted above).
- **Recovery point**: Git-tracked Terraform change (commit `b214e43`), revertible via `terraform apply` after reverting the diff.
- **Outcome**: Success — applied in two separate targeted applies (endpoint first, then the rule, per Oracle's own documented pattern for this resource pair). Two errors hit and fixed along the way: (1) resolver endpoint `name` can't contain hyphens (`^[a-zA-Z_][a-zA-Z_0-9]*$` only) — renamed `onprem-ad-forward` → `onprem_ad_forward`; (2) a single `FORWARD` rule can only have one `destination_addresses` entry — split into two rules. Verified live via `oci dns resolver get`: endpoint `ACTIVE` (forwarding address `10.0.2.41`), both rules present and correctly scoped.
- **Downtime**: 0 minutes
- **Affected**: DNS/network only, no application impact
- **Notes**: Untested end-to-end yet — haven't confirmed an actual OCI host can resolve `livbiko.local` names through this forwarder (nothing AD-dependent runs in OCI yet to test with). If it doesn't work when tested, check Windows Firewall on BIKODC1/BIKODC2 allows inbound DNS (port 53) from the OCI private subnet (`10.0.0.0/16`) — default DNS Server role rules should already allow this, but not yet confirmed.
