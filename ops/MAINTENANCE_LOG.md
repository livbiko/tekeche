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
