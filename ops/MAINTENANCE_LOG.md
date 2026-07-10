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
- **Notes**: Tested end-to-end same day (2026-07-08) from the OCI standby instance via a Bastion port-forwarding session — `dig @169.254.169.254 _ldap._tcp.dc._msdcs.livbiko.local SRV` correctly returned all three on-prem DCs. Confirmed working, not just applied.

## 2026-07-08 — Allow MX68's Meraki-cloud ports (TCP 46294/55261) on BikoFW-SRX

- **Type**: Planned maintenance
- **Duration**: ~5 minutes (recovery point, stage, commit confirmed, validate, finalize)
- **Risk level**: High (production firewall policy addition — same device fronting RRAS/BIKODC's working tunnel)
- **Changes made**: On BikoFW-SRX: address-book object `mx68-wan` (`192.168.1.214/32`), applications `app-tcp-46294`/`app-tcp-55261`, application-set `as-meraki-cloud`, and policy `PF-MERAKI-CLOUD` (`from-zone dmz to-zone untrust`, source `mx68-wan`, destination any, permit). Requested by user for MX68's outbound Meraki-cloud connectivity (VPN registry UDP 9353 + two other cloud ports). UDP 9353 was **not** added — already covered by the pre-existing `dmz-to-untrust` policy's `junos-udp-any` match, confirmed via `show configuration security policies from-zone dmz to-zone untrust` before making changes, so a dedicated rule for it would've been dead config (same redundancy lesson as the earlier `server-access` cleanup).
- **Recovery point**: Full config backup (945 lines, session scratchpad) + Junos rescue snapshot taken before the change; committed via `commit confirmed 10` before finalizing.
- **Outcome**: Success — `show | compare` confirmed a clean diff (no stray uncommitted config from other sessions this time); RRAS tunnels re-verified `UP`/IKE+ESP established immediately after commit, no regression; finalized with plain `commit`.
- **Downtime**: 0 minutes
- **Affected**: Network/firewall only, no application impact
- **Notes**: As with the earlier UDP 500/4500 change, this SRX was already established (via direct inspection: ARP, interfaces, Hub Manager UI confirmation) to not be in the direct path between `192.168.1.0/24` and the internet — that's the Hub Manager's job. User confirmed wanting this rule added regardless, citing a traffic flow (Hub Manager → BikoFW-SRX → MX68) not otherwise confirmed via this session's diagnostics. Added as requested; no functional verification possible since MX68's tunnel is still down independent of this.

## 2026-07-08 — ⚠️ Decommission RRAS ↔ OCI VPN (step 1 of migration to BikoFW-SRX + MX68)

- **Type**: Planned maintenance (destructive)
- **Duration**: ~10 minutes (recovery point, plan preview, destroy, verify, code cleanup)
- **Risk level**: **High — known, accepted outage.** This was not a "risk of breaking something," it was a certain, immediate removal of the only working on-prem↔OCI path, with no working replacement in place at time of removal.
- **Changes made**: Destroyed `oci_core_cpe.onprem`, `oci_core_ipsec.onprem`, and both tunnel management resources (`tunnel1`/`tunnel2`) via targeted `terraform destroy`. `vpn.tf`/`vpn_tunnels.tf` rewritten to remove the resource definitions (full prior config recoverable from git history at/before commit `96dd78b`).
- **Why**: User's explicit, multi-confirmed instruction: migrate on-prem↔OCI connectivity from RRAS to a new BikoFW-SRX (edge router) + MX68 (SD-WAN transport) architecture, starting with a full removal of the RRAS side. I raised the specific technical consequence (immediate loss of the only working path, no ETA to restore, since MX68's tunnel is not yet functional) **three times** across the conversation before proceeding, each time getting explicit re-confirmation, most directly with "remove RRAS now."
- **Recovery point**: Full Terraform state snapshot of all 4 resources saved to session scratchpad before destruction; full resource definitions also recoverable from git history (commits before `96dd78b`). Restoration = re-add the resource blocks (from git history) and `terraform apply` — will provision new CPE/connection/tunnels (not restore the exact same OCIDs) and require re-configuring RRAS on BIKODC with the new tunnel endpoint IPs/PSK.
- **Outcome**: Destroy succeeded cleanly — `terraform plan -destroy` previewed exactly `4 to destroy` before executing; confirmed removal both via `terraform state list` and directly via OCI API (`oci search resource structured-search` — only `tekeche-mx68-ipsec` remains, `tekeche-ipsec` gone entirely); post-destroy `terraform plan` clean (only unrelated pre-existing DNS-rule cosmetic drift, nothing trying to recreate the destroyed resources).
- **Downtime**: **Ongoing, open-ended, as of this entry.** OCI has zero working route to `192.168.1.0/24` — this breaks: the Load Balancer's ability to reach the on-prem primary backend (BIKODC `192.168.1.100`), MongoDB/Redis replication between on-prem and the OCI standby, and the AD DNS forwarding built earlier the same day (targets `192.168.1.102`/`.103`, now unreachable from OCI). Restoration requires either (a) reverting this change, or (b) MX68's tunnel actually working (still blocked, open Meraki TAC case, no ETA) **and** BikoFW-SRX routing/OCI static routes being built for `192.168.1.0/24` via that path (not yet done as of this entry).
- **Affected**: Production — on-prem↔OCI connectivity for the entire `192.168.1.0/24` network.
- **Notes**: RRAS itself (the Windows Server role + `OCI-Tunnel1`/`OCI-Tunnel2` S2S interfaces on BIKODC) was **not** touched — only the OCI-side resources were removed. RRAS will simply show those interfaces as disconnected/failing to connect, since their remote endpoints no longer exist. Next steps for the migration: build BikoFW-SRX static routing (`10.0.0.0/16` via MX68 `192.168.128.1`) + security policy for the `dmz` zone, get MX68's tunnel ESP issue resolved (Meraki TAC), then add OCI-side static routes/security-list rules for `192.168.1.0/24` on the MX68 connection. See `project_livbiko_ad_to_oci.md` memory for full context and next-step tracking.

## 2026-07-08 — Remove MX68 ↔ OCI VPN entirely (abandoned approach)

- **Type**: Planned maintenance (destructive)
- **Duration**: ~10 minutes (recovery snapshots both sides, plan preview, OCI destroy, Meraki peer removal, verify, code cleanup)
- **Risk level**: High in principle (production VPN resource), but net-neutral in practice — this tunnel never carried working traffic (ESP never established across ~3 days of troubleshooting), so removal doesn't change the functional (already-down) state.
- **Changes made**: OCI: destroyed `oci_core_cpe.mx68`, `oci_core_ipsec.mx68`, both tunnel management resources via targeted `terraform destroy`. Meraki: `PUT /organizations/1685535/appliance/vpn/thirdPartyVPNPeers` with an empty peers array, removing both `OCI-MX68-Tunnel1`/`OCI-MX68-Tunnel2`. `vpn_mx68.tf`/`vpn_mx68_tunnels.tf` rewritten to remove the resource definitions (recoverable from git history before commit `493a620`).
- **Why**: User decided to abandon the MX68 tunnel approach entirely rather than continue waiting on the unresolved Meraki TAC case — explicitly confirmed when asked about intent (vs. rebuilding fresh).
- **Recovery point**: Full Terraform state snapshot (4 resources) + full Meraki peer JSON (both peers, including secrets) saved to session scratchpad before removal. Git history has the full prior `.tf` definitions.
- **Outcome**: Success — OCI destroy previewed exactly `4 to destroy` before executing; both sides verified clean afterward (`oci search resource structured-search` for ipsecconnection returns zero items tenancy-wide; Meraki peers list returns `{"peers":[]}`). Post-removal `terraform plan` clean (only the same pre-existing unrelated DNS-rule cosmetic drift as the RRAS removal).
- **Downtime**: None additional — this tunnel wasn't carrying traffic before removal either.
- **Affected**: None functionally. Combined with the earlier RRAS removal the same day, **OCI now has zero site-to-site VPN connections of any kind** — on-prem↔OCI connectivity is fully down with no active recovery path in progress, pending a decision on what to build next.
- **Notes**: `networking.tf` still has route-table and security-list rules referencing `var.mx68_lan_cidr` (`192.168.128.0/24`) — now orphaned (no tunnel routes that CIDR), left in place since not explicitly requested to remove. The Meraki support case doc (`Desktop\Tekeche infrastructure\meraki-support-case-mx68-vpn.md`) still describes the now-deleted tunnel — worth closing or updating with Meraki if the case is still open.

## 2026-07-08 (later) — Rebuild MX68 ↔ OCI VPN fresh from scratch (identical result)

- **Type**: Planned maintenance
- **Duration**: ~10 minutes (restore config from git, recreate 4 OCI resources, recreate 2 Meraki peers, poll ~3.5 min)
- **Risk level**: Low — pure recreation of previously-removed, non-functional resources; no impact to anything else (nothing else depends on this tunnel).
- **Changes made**: Restored `vpn_mx68.tf`/`vpn_mx68_tunnels.tf` from git history (commit `eccc579`), recreated `oci_core_cpe.mx68`, `oci_core_ipsec.mx68`, both tunnel management resources (`terraform apply`, confirmed `4 to add`). Recreated both Meraki non-Meraki VPN peers with new endpoint IPs (`152.67.131.20`, `132.145.67.60` — different from the original pair, since new OCIDs got new public IPs) and identical crypto/secret.
- **Why**: User asked to try again fresh — no new information suggesting the underlying issue was fixed, explicitly acknowledged.
- **Recovery point**: N/A (this was itself a recreation from a recovery point; nothing new to protect against).
- **Outcome**: Identical to every prior attempt. IKE established immediately (no reboot needed this time). ESP never established across 10 checks over ~3.5 minutes. Meraki `reachability: unknown` for both peers throughout.
- **Downtime**: None (this tunnel carries no traffic regardless of its state).
- **Affected**: None. On-prem↔OCI connectivity remains fully down (no working tunnel of any kind, matching the state since the RRAS removal earlier the same day).
- **Notes**: Important confirmation — a fully fresh rebuild (new OCIDs, new public IPs, new tunnel objects both sides) hit the exact same wall as the original. Rules out stale state/config drift as a cause. Root cause is confirmed structural, not incidental — don't attempt another blind rebuild without new information from Meraki TAC. See `project_meraki_mx68_vpn.md` memory for the full attempt history (now 5+ independent attempts).

## 2026-07-08 (even later) — Force NAT-T on MX68 tunnels (test, ruled out)

- **Type**: Planned maintenance (diagnostic test)
- **Duration**: ~5 minutes (change + ~3 min poll)
- **Risk level**: Low — isolated attribute change on 2 already-non-functional tunnel resources.
- **Changes made**: `nat_translation_enabled` changed from `AUTO` to `ENABLED` on both `oci_core_ipsec_connection_tunnel_management.mx68_tunnel1`/`mx68_tunnel2` (`terraform apply`, confirmed `2 to change` scoped diff).
- **Why**: New hypothesis — OCI's NAT auto-detection during IKE_SA_INIT could be misfiring for this specific NATed peer, causing ESP to be sent as raw protocol-50 instead of UDP/4500 NAT-T-encapsulated, which would explain Phase 1 succeeding (plain UDP 500) while Phase 2 data-plane packets get lost at the NAT device.
- **Outcome**: No effect — both tunnels remained `DOWN`/`is-esp-established: false` across 8 checks over ~3 minutes post-change.
- **Downtime**: None.
- **Affected**: None.
- **Notes**: This exhausts essentially every self-service hypothesis worth testing blindly (see `project_meraki_mx68_vpn.md` for the full tally: crypto, traffic selectors, firewall/NAT path, reachability, localId/remoteId, stale state via full rebuild, and now forced NAT-T). Recommend treating this as fully blocked on Meraki TAC's device-side debug log going forward, not inventing further guesses.

## 2026-07-09 12:35 — Admin alerts switched to Brevo SMTP relay

- **Type**: Planned maintenance
- **Duration**: ~15 minutes
- **Risk level**: Medium
- **Changes made**: `tekeche-api/src/services/alert.service.js` now sends admin alerts (cancellation spikes, stuck trips, disk space, etc.) via Brevo SMTP relay as `noreply@tekeche.com` instead of raw Gmail SMTP, reusing the same authenticated relay OTP already uses. Recipient (`assalehervekouame@gmail.com`) unchanged. Falls back to Gmail SMTP if `BREVO_SMTP_KEY` unset. Commit `633e89d`.
- **Recovery point**: `2026-07-09_12-35-39_before-switching-alert-service-js-to-bre`
- **Outcome**: Success — 8/9 Test-Build.ps1 checks passed
- **Downtime**: 0 minutes
- **Affected**: API (alert.service.js only)
- **Notes**: "Full booking flow (automated)" check failed — cause confirmed unrelated to this change (no driver was online in the test app at run time, a pre-existing environmental precondition; the E2E test explicitly reported "No online+available standard driver found"). All other 8 checks passed clean (PM2, health, MongoDB, Redis, auth, driver API, driver count, no crashes). User reviewed and explicitly approved proceeding as a documented exception to the automatic rollback trigger rather than rolling back a change with no code-level relationship to driver online status. Context: this change was prompted by a request to stop the (already-dead, disabled 10 days prior in commit 412afbe) `no_drivers_online` alert email and stop using the personal Gmail account for admin alert sending.

## 2026-07-09 13:37 — BikoFW-SRX <-> OCI VPN applied + rebuilt to Oracle template defaults

- **Type**: Planned maintenance
- **Duration**: ~90 minutes (initial apply + crypto rebuild)
- **Risk level**: High (initial apply) / Medium (crypto rebuild)
- **Changes made**:
  1. Applied drafted IPsec VPN config to BikoFW-SRX (dmz zone ike/tcp-encap fix, IKE/IPsec proposals, st0.1/st0.2, DMZ-TO-OCI/OCI-TO-DMZ policies, static route to 10.0.0.0/16). Discovered and fixed a routing gap: `external-interface irb.50` on the IKE gateway only sets identity, not the actual outbound route — default route still went via MX68 (`ge-0/0/0.0`). Added `/32` static routes for both OCI tunnel endpoints via Hub Manager (192.168.1.254) to route IKE/ESP out the intended dmz path instead of through MX68.
  2. User requested rebuild to match Oracle's official SRX configuration template exactly: switched both tunnels from SHA2_256/AES256/Group14 to SHA2_384/AES256/Group5 (phase1) and HMAC_SHA2_256_128->HMAC_SHA1_128/Group5 (phase2) on both OCI (`ops/oci/vpn_srx_tunnels.tf`, commit `bfd1f94`) and SRX (IKE-PROP-OCI, IPSEC-PROP-OCI, IPSEC-POL-OCI). Added DPD (INITIATE_AND_RESPOND, 20s) on both sides, `vpn-monitor` + `vpn-monitor-options`, `df-bit clear` on both VPN objects, and `security flow tcp-mss ipsec-vpn mss 1387` on SRX. Declined the full literal Oracle template (BGP/dedicated public interface/new zones) as incompatible with SRX's actual NATed topology behind Hub Manager — kept existing `dmz`/`VPN` zones and object names, only crypto + reliability settings adopted from the template.
- **Recovery points**: `2026-07-08_19-46-55_before-bikofw-srx-oci-vpn-config-apply`, `2026-07-09_13-37-49_before-rebuilding-bikofw-srx-oci-vpn-cry` (both include Junos rescue config save + full `show configuration | display set` backup)
- **Outcome**: Success — both tunnels UP on OCI and SRX (tunnel1 140.238.94.206/st0.1, tunnel2 152.67.132.126/st0.2), IKE + IPsec SAs established, `wizard_dyn_vpn`/st0.0 and pre-existing dmz policies unaffected. Note: tunnel1 did not establish at all until the crypto rebuild (unexplained stall with the original SHA-256/Group14 config despite correct routing/reachability) — resolved as a side effect of the rebuild, root cause not conclusively identified.
- **Downtime**: ~1-2 minutes (tunnel2 renegotiation gap during the crypto rebuild; no production traffic depends on this VPN yet)
- **Affected**: Network infrastructure (BikoFW-SRX, OCI DRG/IPSec connection) only — no application/API impact
- **Notes**: End-to-end ping from SRX (192.168.1.1) to OCI standby (10.0.2.10) got no reply post-tunnel-up — likely DRG route-table/security-list propagation, not yet investigated (separate from tunnel establishment, flagged as a follow-up). User still needs to complete: RRAS+VPN step on the standby side and MongoDB RS `rs.add()` per `terraform output next_steps`, unrelated to this SRX work.

## 2026-07-09 14:06 — Investigated "erreur reseau" login reports; found and attempted fix for NLB/OCI routing gap (INCOMPLETE)

- **Type**: Incident investigation + attempted fix
- **Duration**: ~2 hours (investigation) + ~15 min (attempted fix)
- **Risk level**: Medium
- **Trigger**: User reported multiple users seeing "Erreur reseau, verifiez votre connexion" on app launch/login.
- **Investigation findings** (all confirmed, high confidence):
  1. Backend itself healthy throughout — pm2 online, 0 restarts, `/health` returns 200 with `db:connected` both locally and via `api.tekeche.com`, no 5xx/crashes in logs.
  2. OCI LB (`main-backends`) reports primary backend `192.168.1.100:443` (on-prem NLB VIP) as **CRITICAL/CONNECT_FAILED**, backup `10.0.2.10:443` (OCI standby) as OK — meaning **all public `api.tekeche.com` traffic has been failing over to the OCI standby**, which per [[project_oci_standby_cloudinit_fixes]] does not have MongoDB in the replica set. Likely root cause of the reported login failures (standby DB lacks live user/OTP/session data).
  3. Traced the LB→on-prem path: OCI routing (DRG route table, `tekeche-public-rt`) and security lists are all correctly configured — traffic reaches BikoFW-SRX fine via the new SRX↔OCI VPN (see [[project_srx_oci_vpn]]).
  4. Root cause identified via SRX flow-session trace: SRX accepts inbound SYN to `192.168.1.100:443` from OCI (`10.0.1.38`) but **never delivers a reply** (`Out: ... Pkts: 0, Bytes: 0`) — while same-subnet local traffic (`Test-NetConnection` from `192.168.1.101`) works fine.
  5. Confirmed via `show arp`: SRX cannot resolve ARP for `192.168.1.100` at all (`ping` from SRX = 100% loss, no ARP entry ever created). Root cause: **TekecheCluster NLB (192.168.1.100, nodes BikoDC/BikoDC1) runs in MULTICAST operation mode** — cluster MAC `03-bf-c0-a8-01-64` is a multicast address. Routers (including SRX) cannot resolve/forward to a multicast MAC via normal unicast ARP/IP forwarding — this only ever worked for same-L2-segment clients, never for anything routed in (which is why this was invisible until the SRX↔OCI VPN made OCI-routed traffic to this VIP possible for the first time).
- **Attempted fixes**:
  1. Static ARP entry on SRX (`irb.50` → `192.168.1.100` = multicast MAC) — **rejected by Junos**: "Invalid unicast mac address" — Junos refuses to accept a multicast MAC as a static ARP target at all. Confirmed dead end, not just a config nuance.
  2. Switch NLB from MULTICAST to UNICAST mode (`Set-NlbCluster -HostName localhost -InterfaceName Ethernet0 -OperationMode Unicast`) — the standard, Microsoft-documented fix for this exact class of problem. **Failed after ~12 minutes** with `The remote procedure call failed. (0x800706BE)`. Left `BikoDC` stuck showing `Converging` state (vs `BikoDC1: Converged(default)`) and `OperationMode` unchanged at `MULTICAST` — i.e., the change did not take effect; cluster reverted to original (working, service-wise) state, just with a cosmetic stuck status flag on one node.
- **Recovery points**: `2026-07-09_15-44-50_before-adding-static-arp-entry-on-bikofw` (SRX), `2026-07-09_15-55-13_before-switching-tekechecluster-nlb-from` (NLB) — SRX side fully reverted (rollback 0, verified clean `show | compare`); NLB side never fully applied, no rollback needed.
- **Current state**: Service is NOT down — `192.168.1.100:443` still responds locally, `api.tekeche.com/health` still returns 200 (via OCI standby failover). Primary backend (on-prem) is still unreachable from OCI, so real login traffic is likely still hitting the standby. `BikoDC` NLB node has a stuck (cosmetic, not confirmed service-impacting) "Converging" status.
- **User decision**: Leave the NLB state as-is for now rather than retry or investigate the BikoDC↔BikoDC1 RPC failure further today. **Not resolved — root cause understood, fix path identified (unicast mode), but blocked on an unrelated node-to-node RPC failure between BikoDC and BikoDC1 that needs its own investigation before retrying.**
- **Downtime**: 0 minutes confirmed (VIP kept responding throughout)
- **Affected**: Network infrastructure (BikoFW-SRX ARP attempt, TekecheCluster NLB) — no application code changed
- **Follow-up needed**: (1) Investigate why `BikoDC`↔`BikoDC1` RPC communication failed during the NLB config change — possible firewall/DNS/RPC-service issue between the two nodes, independent of today's VPN work. (2) Once that's resolved, retry the MULTICAST→UNICAST switch. (3) Until fixed, real user logins likely continue to hit the OCI standby's incomplete DB — consider whether the standby's MongoDB replica-set gap ([[project_oci_standby_cloudinit_fixes]]) should be prioritized as a faster mitigation (make the standby a fully valid failover target) instead of / in addition to fixing NLB.

## 2026-07-09 17:10 — Rebooted BikoDC to clear stuck NLB Converging state

- **Type**: Planned maintenance
- **Duration**: TBD (in progress)
- **Risk level**: High (full API downtime during reboot window)
- **Reason**: Following up on the incomplete MULTICAST->UNICAST NLB fix attempt (see 2026-07-09 14:06 entry / [[project_nlb_multicast_oci_routing]]) - BikoDC left stuck showing "Converging" status after a failed RPC call. Rebooting to force a clean NLB driver reload.
- **Pre-checks performed**: MongoDB (Automatic startup) and W3SVC/IIS (Automatic startup) both confirmed auto-start; PM2 boot-resurrect scheduled task (`Tekeche-PM2-Startup`, SYSTEM, BootTrigger) confirmed present with a clean exit=0 history across 5 prior reboots; `pm2 save` run immediately before reboot to refresh the stale (5-day-old) dump file.
- **Recovery point**: `2026-07-09_17-10-59_before-rebooting-bikodc-to-clear-stuck-n`
- **Expected downtime**: ~5-8 minutes
- **Affected**: API (all PM2-managed processes), NLB node BikoDC
- **Outcome (confirmed later same evening)**: Reboot completed, but did **not** fix the stuck state — `Get-NlbCluster`/`Get-NlbClusterNode` afterward still showed `BikoDC` in `Converging` and `OperationMode: MULTICAST` unchanged. Root cause remains open; see the 2026-07-09 21:00-23:15 entry below for the separate (unrelated) DNS/MongoDB fix applied that same night.

## 2026-07-09 21:00-23:15 — Fixed BIKODC DNS self-registration + MongoDB replica-set hostname/dead-member issues (root cause of ongoing "Erreur reseau" reports)

- **Type**: Incident investigation + fix, in 3 parts
- **Duration**: ~2 hours investigation, ~20 minutes total hands-on-keyboard changes across 3 maintenance windows
- **Risk level**: High (domain controller DNS config, MongoDB primary restart, replica-set reconfig — each individually approved)
- **Trigger**: Continuation of the same-day "Erreur reseau" investigation (see 14:06 entry above). Separately, live `pm2 logs tekeche-api` showed a distinct, actively recurring symptom not covered by the NLB theory: `DB connection failed: connection to 192.168.128.101:27017 timed out — retrying in 15s`, cycling with successful reconnects to `192.168.1.101`, roughly every 60-75 seconds, for hours.

- **Root cause 1 — BIKODC DNS self-registration**: BIKODC has 3 NICs (`192.168.1.101` production LAN, `192.168.50.101` unknown second network, `192.168.128.101` — same subnet as the Meraki MX68 site LAN). All 3 had identical interface metric (25) and `RegisterThisConnectionsAddress = True`, so `BikoDC.livbiko.local` resolved to any of the three unpredictably. `dns_ad_forwarding.tf` had already worked around a version of this (excluding BIKODC's then-APIPA address `169.254.0.36` from AD DNS forwarding — see comment in that file) without fixing the underlying registration behavior.
- **Root cause 2 — MongoDB replica-set member configured by hostname**: `rs.conf()` had `BIKODC.livbiko.local:27017` / `BIKODC1.livbiko.local:27017` as member hosts (confirmed via authenticated `rs.conf()` query) rather than IPs. Combined with root cause 1, the mongod driver's internal replica-set network interface periodically resolved the primary's own hostname to the wrong NIC (and in one observed case, an IPv6 link-local address — indicating NetBIOS/LLMNR fallback resolution, a separate mechanism from DNS registration and unaffected by the DNS fix alone).
- **Root cause 3 — dead OCI standby replica-set member**: `10.0.2.10` (the OCI standby, added as a passive/priority-0/votes-0 member per [[project_oci_standby_cloudinit_fixes]]) has been unreachable (`health: 0`) the whole time. mongod's `NetworkInterfaceTL-ReplNetwork` was continuously retrying it every ~10-15s, each failed attempt logged as `"Operation timed out while waiting to acquire connection"` — this was tying up internal connection-pool resources and causing intermittent hangs on unrelated same-box app queries, most visibly breaking `POST /api/auth/send-otp` (reproduced 5/5 failures, root-caused via `[OTP RATE] DB check failed, allowing through: connection ... 192.168.1.101:27017 timed out` in app logs correlating exactly with mongod's internal timeout log entries).

- **Fixes applied** (each its own approved maintenance window + recovery point):
  1. `Set-DnsClient -InterfaceAlias "Ethernet1"/"Ethernet2" -RegisterThisConnectionsAddress $false` on BIKODC; confirmed via `dcdiag /q` clean before/after (aside from a pre-existing, unrelated `SystemLog` failure from stale RRAS demand-dial error events, already known from RRAS decommissioning on 2026-07-08).
  2. MongoDB `admin` user password reset via standalone recovery procedure (stop `MongoDB` service, start standalone mongod on port 27018/no-auth/localhost-only against the same data files, `changeUserPassword`, shut down standalone, restart service normally). BIKODC was primary at the time in this 2-node-no-arbiter set, so this caused a brief (~1-2 min) full write-outage domain-wide until the service came back and re-established itself as primary (confirmed automatic, no manual election needed). New credentials stored at `C:\Users\Administrator\mongo-creds.txt`.
  3. `rs.reconfig()` changing `members[0].host`/`members[1].host` from hostnames to literal IPs (`192.168.1.101`, `192.168.1.102`). Applied cleanly, no stepdown observed. Required a `pm2 reload tekeche-api` afterward to clear the app's own in-memory driver topology cache before the fix was verifiable in logs.
  4. `rs.remove('10.0.2.10:27017')` — removed the dead OCI standby (non-voting, so no quorum impact) to stop the connection-pool contention. Confirmed the `"Operation timed out while waiting to acquire connection"` log line stopped appearing immediately after.

- **Recovery points**: `2026-07-09_21-25-26_before-fix-bikodc-dns-self-registration`, `2026-07-09_22-18-49_before-reset-local-mongodb-admin-passwor`, `2026-07-09_22-29-56_before-mongodb-rs-reconfig-hostnames-to`, `2026-07-09_23-12-22_before-rs-remove-10-0-2-10-dead-oci-stan`.
- **Verification**: `Test-Build.ps1` — initially 8/9 (only `Full booking flow (automated)` red, confirmed unrelated: test script reported `No online+available standard driver found`, a test-data precondition since no driver was logged into the app, not a connectivity issue). Resolved by inserting one synthetic test driver (`assalehervekouame+driver1@gmail.com`, Gmail +alias never used on a real device — chosen specifically to avoid marking any real tester's live account online, since this test dispatches an actual ride over a real socket connection). Re-ran clean: **9/9 checks passed**, including the full automated booking flow end-to-end (OTP auth, socket dispatch, accept, status progression, completion). Note: the test script's own cleanup disconnects its socket at the end, which correctly reverts the driver to offline via the normal disconnect handler — the driver's `isOnline`/`isAvailable`/`socketId` needs to be reset before each future run of this test (including before `Set-KnownGood.ps1`, which re-runs the full suite itself).
- **Downtime**: ~1-2 minutes (MongoDB write-outage during the password-reset window only); no downtime from the DNS fix, `rs.reconfig()`, `rs.remove()`, or the test-driver insert.
- **Affected**: BIKODC DNS client config (2 NICs), MongoDB `admin` user credentials, `rs.conf()` member list (now 2 members instead of 3), one new synthetic driver document (`tekeche.drivers`, `_id: 6a501eff9ec62860a8abc114`).
- **Result**: `Set-KnownGood.ps1` run successfully — **Build #17 marked Known Good** (API `633e89de` / Mobile `564ebbc6`).
- **Follow-up needed**: (1) Get the OCI standby's MongoDB actually healthy and re-add it properly (per [[project_oci_standby_cloudinit_fixes]]'s still-open item), rather than leaving it removed indefinitely. (2) The unrelated NLB multicast issue from the 14:06/17:10 entries is still fully open.

## 2026-07-09 20:00 to 2026-07-10 03:00 — OCI Kubernetes (OKE) migration, Phases 0-2

- **Type**: New infrastructure build (approved multi-phase plan, see plan file / user-approved scope)
- **Duration**: ~7 hours across Phase 0 (Terraform hygiene), Phase 1 (OKE cluster + node pool + IAM), Phase 2 (deploy tekeche-api)
- **Risk level**: High (new production infrastructure; each phase individually risk-classified and approved)

**Phase 0** — Terraform provider upgraded 5.47.0 → 8.22.0 (one cosmetic DNS-normalization diff, silenced via `lifecycle.ignore_changes`). State migrated off local disk into OCI Object Storage (`tekeche-tfstate` bucket) — hit and resolved a real compatibility wall: Terraform's S3 backend changed AWS SDKs in v1.6.0 in a way OCI's S3-Compatibility API rejects (chunked encoding unsupported); fixed by pinning to Terraform **v1.5.7** specifically for this project (`C:\tools\terraform-1.5.7\terraform.exe`, `required_version` constraint updated) — see [[project_oci_terraform_version_pin]].

**Phase 1** — Provisioned OKE cluster (Basic tier, free control plane), 2-node pool (`VM.Standard.E4.Flex`, spread across 2 ADs, KMS-encrypted boot volumes), dedicated NSGs, new subnets (`10.0.4.0/24` nodes, `10.0.5.0/28` API endpoint, private), one OCIR repo (`tekeche-api`), and IAM (OKE service policy + node dynamic group). 18 resources, clean apply, no impact to existing infra. Also fixed the actual root cause of the ongoing MongoDB `192.168.128.101` flapping (see the entry above this one) as part of this phase's original scope.

**Phase 2** — Wrote and applied full K8s manifest set (`ops/k8s/tekeche-api/`: namespace, ConfigMap, Secret-creation script, Deployment, Service). Built the tekeche-api Docker image on an OKE node via `podman` (installed there specifically to avoid touching BIKODC's own container/virtualization config). Hit and resolved two separate, serious blockers:
1. **User-level OCI Auth Tokens are rejected for OCIR login in this tenancy, for an unresolved reason** — extensive troubleshooting ruled out every self-serviceable cause (see [[project_ocir_auth_token_blocked]]). Switched to instance-principal-based access tokens instead (`oci container-registry access-token get --auth instance_principal`), which worked.
2. **The OKE node dynamic group's matching rule never actually matched any real instance** — originally `instance.pool.id` (a guess, already flagged as unverified in the original code comment), confirmed via direct 403s from OCIR ("not authorized") on the exact node instance. Fixed to use `instance.compartment.id` + the `Oracle-Tags.CreatedBy=oke` tag OCI automatically applies (see [[project_oke_dynamic_group_matching_fix]]). Also found a Terraform apply silently not taking effect on this field — had to set it directly via `oci iam dynamic-group update` and verify with a fresh `get`, not trust `terraform state show`.
3. Also needed a standard Kubernetes `imagePullSecret` (`ocir-pull-secret`, built from the same instance-principal token) since this node pool has **no kubelet image-credential-provider configured at all** — OKE's advertised "nodes pull automatically via instance principal" didn't apply here. And a `securityContext.runAsUser: 1000` fix (Dockerfile's `USER node` — numeric UID needed since `runAsNonRoot` can't verify a symbolic username ahead of time).

- **Final blocker found (not fixed tonight)**: after all of the above, the pod builds/deploys/starts successfully but **crash-loops because it cannot reach on-prem MongoDB/Redis at all** — confirmed via direct testing that OCI compute in the new OKE subnets can't reach *any* on-prem service (ping and RDP to BIKODC both fail too, not just Mongo), while intra-VCN connectivity (OKE node ↔ OCI standby VM) works fine. Very likely the BikoFW-SRX firewall policy predates these new subnets and was never updated to permit their traffic through — see [[project_oci_onprem_network_gap]] for full detail and next steps. Deliberately **not fixed tonight** — live production firewall/VPN device, needs its own dedicated session, out of scope for a Kubernetes deployment task at this hour.
- **Recovery points**: `2026-07-09_20-08-33_before-provision-oke-cluster-node-pool-o`, `2026-07-09_23-21-19_before-insert-synthetic-test-driver-for` (also covers Phase 2 work; no destructive changes made overall — only additive infra + a widened IAM policy on a scoped dynamic group).
- **Downtime**: None — all Phase 0-2 work is additive/new infrastructure; zero production traffic touched.
- **Affected**: New OCI resources only (OKE cluster/nodes/IAM/OCIR), new Kubernetes manifests in `tekeche` namespace. No existing production resource modified except the IAM policy widening (`tekeche-oke-nodes-ocir-policy`, scoped only to the 2 node instances).
- **Follow-up needed**: (1) Fix the OCI↔on-prem network gap (SRX firewall policy) — blocks both finishing Phase 2 validation and starting Phase 3. (2) Consider whether the tenant-wide user Auth Token issue needs an Oracle Support ticket. (3) Phases 3-7 of the migration (production cutover onward) remain fully open, deliberately deferred past tonight given the hour and Phase 3's risk level.

## 2026-07-10 08:00-09:00 — Resolved the OCI↔on-prem network gap: root cause was NOT the SRX firewall

- **Type**: Continuation of the Phase 2 network-gap investigation from the entry above
- **Duration**: ~1 hour
- **Risk level**: Medium (two additive, low-blast-radius changes on BIKODC — a static route and a firewall rule)

**Root cause found, and it corrects the previous entry's leading theory**: not the BikoFW-SRX firewall policy at all.
1. BIKODC had no return-route for `10.0.0.0/16` (OCI's VCN) — only a default route via the Hub Manager/internet router (`192.168.1.254`), not via BikoFW-SRX (`192.168.1.1`) where the VPN terminates. Added a static route (`10.0.0.0/16 via 192.168.1.1`) — fixed ICMP (ping) round-trips immediately, confirmed 0% packet loss.
2. BIKODC's Windows Firewall had no rule allowing MongoDB (27017) from the new OCI subnet — the 4 existing rules were all scoped to specific known IPs. Added `MongoDB - Allow OCI VCN` (10.0.0.0/16).
3. **The extensive SRX firewall investigation in the previous entry was chasing a false signal.** The test method (`cat < /dev/tcp/host/port` in bash) reports failure whenever the remote service doesn't proactively send data first — exactly how MongoDB (and Redis) behave. This made a *working* connection look identically broken to a real one. Confirmed via `tcpdump` on the OCI node: the full TCP 3-way handshake to MongoDB succeeds cleanly. The SRX policy/zones/IPsec tunnels were all healthy the whole time and were never the actual problem.
- **Result**: Both tekeche-api pods now `Running`/`Ready` (1/1), confirmed real MongoDB connectivity (`/health` → 200, `db: connected`, consistently, via kube-probe over several minutes).
- **Recovery points**: `2026-07-10_08-00-30_before-add-static-route-10-0-0-0-16-via`, `2026-07-10_08-04-37_before-add-mongodb-firewall-rule-allowin`.
- **Still open (separate, non-blocking)**: Redis (Memurai, on BIKODC1 `192.168.1.102:6379`) still times out — confirmed via `tcpdump` as a genuine failure (SYN retransmission, zero reply), not a test artifact. BIKODC1 already has a *different* existing route to OCI (via BIKODC as gateway, not directly via SRX) and ping to it works fine; the Memurai firewall rule looks fully permissive and the service is listening on the right interface, yet TCP still fails — likely an asymmetric-routing issue between BIKODC1's forward and return paths. Socket.io falls back gracefully to single-node mode without Redis, so this doesn't block the app, just cross-replica real-time fan-out. See [[project_oci_onprem_network_gap]] for full detail and the suggested next diagnostic step (a `tcpdump` capture on BIKODC1 itself).
- **Downtime**: None — both changes are purely additive (new route, new firewall rule), nothing existing was modified or removed.
- **Follow-up needed**: (1) Redis/BIKODC1 connectivity (see above). (2) Phases 3-7 remain open. (3) Consider applying the same route pattern check to BIKODC2 and the OCI standby proactively, in case they have the same missing-route gap.

## 2026-07-10 09:20-09:40 — INCIDENT: accidental full-domain nameserver change caused a live outage

- **Type**: Unplanned incident during Phase 3 TLS certificate setup (not a planned change)
- **Duration**: ~20 minutes from discovery to full restoration
- **Risk level**: High (live production DNS outage, affecting the main site, 3 subdomains, and email authentication)

**What happened**: intended to ask for a narrow NS delegation of a new subdomain (`acme.tekeche.com`, for ACME DNS-01 cert validation) plus 3 CNAME records at register.com. The register.com console instead presented (and the user confirmed) a **full domain nameserver change** for all of `tekeche.com` to OCI's 4 nameservers, switching authoritative DNS for the entire domain away from register.com to the nearly-empty OCI-managed `tekeche.com` zone. By the time this was caught, propagation was already complete (confirmed via 8.8.8.8 and 1.1.1.1) — no window existed to revert before impact.

- **Impact**: `tekeche.com`, `www.tekeche.com`, `staging-api.tekeche.com`, `security.tekeche.com`, and `pay.tekeche.com` had zero DNS records and were fully unreachable for the duration. `api.tekeche.com` was unaffected (already had a Terraform-managed record).
- **Recovery**: reconstructed the zone by racing DNS resolver caches before they expired, catching: SPF, Brevo domain-verification TXT, DMARC policy, and both Brevo DKIM CNAME selectors — plus the 5 missing A records (using the already-documented on-prem public IP `81.130.238.41` from `variables.tf` for everything except `api.tekeche.com`, which already pointed at the OCI LB `79.72.66.42`). Verified all restored records resolve correctly afterward via public DNS.
- **Not independently confirmed complete** — this was opportunistic cache-based reconstruction, not a restore from an actual zone backup. Other records could still be missing and only surface later. See [[project_dns_nameserver_incident_2026_07_10]] for the full incident writeup and what to check if anything DNS/email-related breaks in the future.
- **Silver lining**: this actually simplifies the original Phase 3 cert-issuance plan — `tekeche.com` is now natively editable via OCI DNS API, so ACME DNS-01 challenges no longer need the separate `acme.tekeche.com` delegated zone/CNAME indirection originally planned (that zone is now redundant, low-priority cleanup item).
- **Downtime**: ~15-20 minutes for the 5 affected domains; email deliverability (SPF/DKIM/DMARC) was at risk for a similar window until restored.
- **Follow-up needed**: (1) Watch for any DNS/email issues in the coming days/weeks that might trace back to a record this reconstruction missed. (2) Delete the now-redundant `acme.tekeche.com` OCI zone. (3) Be extremely careful with register.com's UI going forward — it does not clearly distinguish "delegate one subdomain" from "change the whole domain's nameservers."

## 2026-07-10 10:45-11:25 — Phase 3 cert issuance attempted, blocked by an unexplained Let's Encrypt issue

- **Type**: Continuation of Phase 3 (needed fresh TLS certs since the existing certs' private keys are non-exportable from the Windows cert store)
- **Duration**: ~40 minutes across 2 failed attempts
- **Risk level**: Medium (additive — new certificate issuance attempts, no existing cert/traffic touched)

Used `win-acme` with its `PemFiles` store plugin (avoids the non-exportable-key problem entirely by writing plain cert+key files) for `api.tekeche.com`, using the OCI-automated `dns-create.ps1`/`dns-delete.ps1` scripts written earlier tonight (now pointed at the live `tekeche.com` zone directly, no longer needing the `acme.tekeche.com` delegation workaround since the whole domain is now in OCI — see the incident entry above).

- **Real bug found and fixed**: `C:\wacs\settings.json`'s `Validation.DnsServers` was `["[System]"]`, meaning win-acme's propagation pre-check used this box's own configured DNS resolvers — which include on-prem AD DNS servers that turn out to host their own internal, AD-integrated "tekeche.com" zone (very likely deliberate split-horizon DNS pointing at the internal NLB VIP `192.168.1.100` for on-prem clients). This caused the pre-check to see completely unrelated answers and burn all 30 retries (15 min) every single time before even attempting real validation. Fixed by setting `DnsServers` to `["8.8.8.8", "1.1.1.1"]` — confirmed working on the second attempt (correctly queried OCI's real nameserver IPs instead).
- **Unresolved**: even with that fix, and even though win-acme's own pre-check (against the *correct* servers) showed "Incorrect TXT record(s) found" (i.e., saw *something*, just not the right value), **the real Let's Encrypt validation failed with the exact same stale token both times** (`CjLsVnzgaCj-X1apfceB_gedQTwhzembJ-RY6rW36Hw`), despite win-acme generating a genuinely different fresh token each attempt and direct verification confirming the correct token was live in OCI's zone both times. Root cause not identified — looks like caching or order/authorization reuse somewhere in the Let's Encrypt validation path, not a DNS content problem. See [[project_phase3_cert_issuance_blocked]] for full detail and untried next steps.
- **Decision**: stopped after 2 failed attempts rather than keep retrying blindly, since failed ACME validations count against Let's Encrypt's rate limits (typically 5/account/hostname/hour) and the root cause needs proper investigation, not repeated guessing.
- **Downtime**: None — no existing certificate or live traffic was touched; this was entirely about provisioning new, not-yet-used certificates.
- **Follow-up needed**: (1) Investigate the stale-token issue fresh (try a new ACME account, wait longer, or try a different ACME client to isolate whether it's win-acme-specific). (2) Once certs are issued, still need: K8s TLS secrets, Ingress controller deployment, and the actual OCI LB backend repoint to complete Phase 3. (3) The `settings.json` DNS-server fix should be kept regardless — it's a genuine improvement unrelated to this specific blocker.

## 2026-07-10 11:30-14:20 — Phase 3 cert issuance resolved for api.tekeche.com; found and fixed a real OCI LB bug

- **Type**: Continuation of Phase 3 cert issuance, escalating in scope as root causes were found
- **Duration**: ~3 hours across several investigation/fix cycles
- **Risk level**: HIGH (LB/security-list Terraform changes affecting shared production infrastructure); MEDIUM (standby Nginx live edit)

**DNS-01 mystery resolved (no longer pursued)**: `tekeche.com`'s registry-level NS delegation is genuinely still register.com (`dns153/176/214/131.*.register.com`), never actually OCI as previously assumed — confirmed via `nslookup -type=NS`. The stale-token TXT record seen in both prior DNS-01 attempts was a leftover in register.com's real zone; win-acme's automation had been writing fresh tokens into OCI's DNS zone, which no real-world resolver (including Let's Encrypt's own validator) ever consults. Pivoted to HTTP-01 instead, which sidesteps this entirely and is proven to work for this org.

**HTTP-01 attempt 1 — found an IIS bug**: win-acme's extensionless challenge tokens got a 404 from IIS by default (no MIME mapping for empty file extensions). Fixed with a nested `.well-known\web.config` (`mimeMap fileExtension="." mimeType="text/plain"`) on all three proxy sites (`proxy-api-tekeche`, `proxy-staging-api`, `proxy-security-tekeche`). Low risk, no binding/traffic changes.

**HTTP-01 attempt 2 — found the standby Nginx gap**: real validation still failed. Traced to the OCI standby VM's Nginx (defined in `compute.tf`'s cloud-init) having no ACME-challenge exception on its port-80 redirect. Patched live via SSH (through the existing OCI Bastion, foreground session only, config backed up first, validated with `nginx -t`, reloaded gracefully — not restarted).

**HTTP-01 attempt 3 — found the real root cause, an OCI LB bug**: still failed. Root-caused to `loadbalancer.tf`: the `http-80` listener shared the same backend set as `https-443` (`main-backends`), whose backends are registered on port 443 only — so ALL plain-HTTP traffic (any listener) was forwarded to each backend's port 443, hitting an SSL listener with plaintext bytes ("400 The plain HTTP request was sent to HTTPS port"). Undetectable from this box's own tests since its local DNS resolution for `api.tekeche.com` never actually traverses the public LB (on-prem AD DNS split-horizon). Confirmed via `curl --resolve api.tekeche.com:80:<LB IP>` forcing the real public path.

- **Fix applied via Terraform**: added a new `http-backends` backend set (port 80 on both on-prem and standby) and repointed the `http-80` listener at it. Also had to add a matching port-80 ingress rule to the private security list (standby was previously only reachable from the LB subnet on 443/5000). Both changes additive/in-place only — `https-443`/`main-backends` untouched, 0 destroys in both applies.
- **Terraform backend friction**: the S3-compatible remote-state backend had no working credentials (two different auth-format attempts both failed). Worked around by temporarily commenting out the `backend "s3"` block, using local state (fetched/pushed via plain `oci os object get`/`put`, not the broken S3-compat path). See [[project_oci_terraform_s3_backend_broken]] — needs a real fix later.
- **Recovery points created**: `2026-07-10_11-59-41_before-re-issue-let-s-encrypt-cert-for-a`, `2026-07-10_13-18-27_before-add-oci-lb-port-80-backend-set-re`.
- **Result**: `api.tekeche.com-pemfiles` cert issued successfully (PEM files in `C:\wacs\pem-out\`, renewal due 2026-09-03). `staging-api.tekeche.com` and `security.tekeche.com` remain blocked — found their A records at register.com are stale, pointing at an old IP (`81.130.238.41`) instead of the OCI LB (`79.72.66.42`); user is fixing directly in register.com's portal.
- **Test-Build.ps1 after**: 8/9 passed; the one failure ("Full booking flow (automated)") is a live precondition (no driver currently online in the app), unrelated to any of today's changes — confirmed by running the underlying test script directly. Not marked known-good yet at user's choice, pending a clean run with a driver online.
- **Downtime**: None — all changes were additive or touched only the not-yet-live OKE/HTTP-01 path; existing HTTPS production traffic (`https-443`/`main-backends`) was never modified.
- **Follow-up needed**: (1) Once register.com A records are fixed, rerun the same win-acme command for staging-api (site id 7) and security (site id 2). (2) Fix the Terraform S3 backend credential format properly. (3) The on-prem NLB (`192.168.1.100`) is now confirmed critical on *both* port 443 and port 80 health checks — same pre-existing [[project_nlb_multicast_oci_routing]] incident, still unresolved. (4) Re-run Test-Build.ps1 with a driver online before marking known-good.

## 2026-07-10 19:11 — Emergency incident: NLB unicast attempt broke MongoDB RS, service degraded ~20 min

- **Type**: Unplanned incident (started as planned maintenance, escalated)
- **Duration**: ~85 minutes total (19:11 change start → ~20:36 final clean Test-Build pass)
- **Risk level**: Classified MEDIUM by `Get-ChangeRisk.ps1`; actual impact was High — real customer-facing outage
- **Changes made**: Attempted to fix the long-standing [[project_nlb_multicast_oci_routing]] issue by switching `TekecheCluster` NLB from MULTICAST to UNICAST (`Set-NlbCluster -OperationMode Unicast`) on BikoDC, following up on the 2026-07-09 attempt that had failed on an RPC error and left BikoDC stuck in `Converging`. This time the switch succeeded and immediately fixed the original goal — OCI's load balancer confirmed `192.168.1.100:443` healthy (`main-backends` status `OK`, zero critical) for the first time.
- **Recovery point**: `2026-07-10_19-11-35_before-switch-tekechecluster-nlb-from-mu`
- **What went wrong**: Unicast mode's source-MAC masking (`MaskSourceMAC`, already `ENABLED` pre-existing, but only consequential once real unicast semantics applied) broke ALL traffic from BikoDC's single NIC, not just cluster-VIP traffic — including the dedicated-IP path (192.168.1.101↔192.168.1.102) that MongoDB replica-set heartbeats and ARR health checks depend on. BikoDC1 became fully unreachable from BikoDC. With only 1 of 2 RS votes reachable, MongoDB lost its primary (`rs.status()` showed BikoDC SECONDARY, BikoDC1 unreachable) and `/health` started returning `503 {"status":"degraded","db":"disconnected"}` — a real, external, customer-facing outage on `api.tekeche.com`.
- **Rollback attempted, failed**: `Invoke-Rollback.ps1 -Latest` — the designated rollback tool — threw a PowerShell parse error (`missing the terminator`) and could not run at all. Root cause found afterward: the script had no UTF-8 BOM, and Windows PowerShell 5.1 misdecoded its em-dash/emoji bytes under the system ANSI codepage, corrupting string literals. Pre-existing latent bug, unrelated to tonight's NLB work, discovered only because we needed the tool mid-incident. **Fixed separately same session** — see below.
- **Manual recovery, harder than expected**: Reverted BikoDC's NLB config to MULTICAST via `Set-NlbCluster` (needed 2 retries — intermittent "RPC server unavailable" from the NLB WMI provider), confirmed at the driver level (`wlbs params` showed `MulticastSupportEnable = ENABLED`, correct MAC `03-BF-C0-A8-01-64`) only after a full `Restart-Service WLBS`. Despite BikoDC's config being fully correct again, **BikoDC↔BikoDC1 connectivity did not recover** — 100% packet loss, ports 135/3389 both closed, even after the user also restarted `WLBS` on BikoDC1 directly. Working theory: 3 rapid source-MAC changes on the same switch port in under an hour (real → unicast-masked `02-bf...` → multicast `03-bf...`) tripped port-security/MAC-flap protection on the physical switch — not something fixable from either server's OS. **Not yet confirmed or resolved** — needs switch-side investigation (port-security violation log / err-disabled port).
- **Actual fix — MongoDB forced standalone-primary**: Since BikoDC1 was unreachable regardless of NLB mode, the real blocker to service was the replica set having no primary, not the VIP. With explicit user approval (HIGH-RISK DB change, mid-incident), force-reconfigured `rs0` to drop BikoDC1 and run BikoDC alone: `rs.reconfig({...single member...}, {force: true})`. This restored `db: connected` and `200 OK` on both local and external (`https://api.tekeche.com/health`) within ~1 minute of applying.
- **Outcome**: Partial. Service fully restored (`Test-Build.ps1`: 8/9 passed — the one failure, "Full booking flow", is the same pre-existing "no driver online" precondition noted in the entry above, unrelated). **But**: (1) the original goal (OCI reachable to on-prem NLB VIP) is lost again — back to MULTICAST, OCI will fail over to the OCI standby (which has its own known Mongo RS gap, see [[project_oci_standby_cloudinit_fixes]]) if on-prem ever goes down; (2) BikoDC1 is still out of the Mongo replica set — **currently running single-node with no DB failover**; (3) switch-level root cause unconfirmed and unresolved. Not marked known-good given this degraded HA state.
- **Downtime**: ~20-25 minutes of degraded/`503` service on `api.tekeche.com` (first observed degraded ~19:37 via Test-Build.ps1, confirmed restored ~19:35-19:40 window based on API-returned timestamps — exact start not pinned since health wasn't polled continuously during the change).
- **Affected**: API, Database (MongoDB RS), all customer-facing traffic during the window
- **Follow-up needed**: (1) Investigate the physical switch for port-security/MAC-flap violations on BikoDC/BikoDC1's ports — likely blocker to full HA recovery. (2) Once BikoDC1 is reachable again, re-add it to `rs0` as secondary and let it resync. (3) The original OCI↔on-prem NLB routing problem ([[project_nlb_multicast_oci_routing]]) is still unsolved — unicast mode is confirmed unsafe on this single-NIC setup; needs a different approach (e.g., second dedicated NIC per node, or fixing the OCI standby's Mongo membership instead so failover doesn't depend on the on-prem VIP being reachable from OCI at all). (4) `Invoke-Rollback.ps1` encoding bug fixed same session (commit `035f8c5`) — worth auditing other ops scripts for the same latent BOM issue.
