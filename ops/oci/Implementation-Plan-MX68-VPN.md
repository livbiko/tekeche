# Tekeche — Engineer Implementation Plan
## Meraki MX68 ↔ Oracle Cloud Infrastructure Site-to-Site VPN

**Version:** 1.0
**Date:** 2026-07-07
**Reference:** `ops/oci/HLD-MX68-VPN.md`, `ops/oci/LLD-MX68-VPN.md`
**Status:** 🔴 BLOCKED — pending Meraki TAC response

---

## 1. Status Summary

| Item | State |
|---|---|
| OCI infrastructure (DRG attachment, CPE, IPSec connection, tunnels) | ✅ Deployed, Terraform-tracked, no known issues |
| Meraki peer configuration | ✅ Applied, crypto/subnets confirmed correct |
| Phase 1 (IKE) | ✅ Established on both tunnels |
| Phase 2 (ESP) | 🔴 Never establishes on either tunnel |
| Production RRAS/BIKODC tunnel | ✅ Unaffected by any change made during this project |
| Support case | 🟡 Filed with Meraki TAC 2026-07-06, awaiting response |

---

## 2. Completed Work (chronological)

1. **Provisioned OCI side** — CPE, IPSec connection, two tunnels with static routing and crypto matching the existing RRAS tunnels. (`ops/oci/vpn_mx68.tf`, `vpn_mx68_tunnels.tf`)
2. **Provisioned Meraki side** — two non-Meraki VPN peers pointing at the OCI tunnel endpoints, matching crypto, `192.168.128.0/24` marked `useVpn: true`.
3. **Diagnosed initial silence** — zero VPN negotiation activity, no `vpn_registry_change` event firing at all after adding the peers.
4. **Rebooted the MX68** via Dashboard API — unstuck the VPN registry; Phase 1 (IKE) started working immediately on both tunnels. Phase 2 did not.
5. **Ruled out firewall/NAT as the blocker**:
   - Confirmed via live ping test (MX68 → OCI tunnel endpoint): clean path, 0% loss.
   - Identified and confirmed the actual on-prem topology (BT Hub Manager → `192.168.1.0/24` → BikoFW-SRX → `192.168.128.0/24`).
   - Added a scoped, approved firewall rule on BikoFW-SRX anyway (HIGH RISK change, properly logged) in case a secondary path through it mattered — no change in outcome, no regression to RRAS.
6. **Ruled out crypto/algorithm mismatch** — direct side-by-side comparison, exact match on both phases.
7. **Fixed traffic-selector mismatch** — added explicit `encryption_domain_config` to the OCI tunnels matching Meraki's policy-based proposal (`192.168.128.0/24 ↔ 10.0.0.0/16`). Applied cleanly via scoped Terraform plan/apply. No change in outcome.
8. **Attempted OCI's own tunnel-error diagnostic** — returned a result that contradicted live tunnel state; determined to be unreliable/stale, not further pursued.
9. **Filed a Meraki TAC support case** (`Desktop\Tekeche infrastructure\meraki-support-case-mx68-vpn.md`) — full topology, config, and diagnostic timeline included; specific ask is for Meraki to check the MX68's local VPN daemon debug log for the actual Phase 2 rejection reason (e.g. `NO_PROPOSAL_CHOSEN`, `TS_UNACCEPTABLE`).

---

## 3. What NOT to Re-Try

To avoid re-doing already-exhausted diagnostic paths, do **not** re-attempt these without new information:

- Rebooting the MX68 again, or toggling `useVpn` off/on — already tried multiple times post-fix, produces no new registry event and no change in tunnel state once the registry is already unstuck.
- Re-checking crypto parameters — confirmed identical, this is not the issue.
- Further firewall/NAT changes on BikoFW-SRX or BT Hub Manager — path is confirmed clean via live ping; not the blocker.
- Trusting `GetIpSecConnectionTunnelError` as a live status source — it returned stale data once already.

---

## 4. Next Actions

### 4.1 While waiting on Meraki TAC
- No further infrastructure changes planned. Infrastructure is in a known-good, stable, non-regressive state (RRAS tunnel unaffected).
- If TAC asks for anything not already in the case doc (packet captures, additional timestamps, specific tunnel OCIDs), pull from LLD §2.2 and §6 for exact identifiers/commands.

### 4.2 When Meraki TAC responds
1. Read their finding against LLD §5 (Diagnostic Findings) to see if it's consistent with what's already been ruled out.
2. If they identify a Meraki-side config fix → apply via the Dashboard API (see LLD §3 for current peer JSON as the baseline to diff against).
3. If they identify an OCI-side requirement Meraki needs (e.g. a specific proposal ordering, NAT-T forcing) → this would be a **new** OCI tunnel config change; treat as MEDIUM risk (isolated to these two not-yet-working tunnels, same low blast radius as the §2.3 traffic-selector change), use `terraform plan -target=` scoped to the two tunnel resources, verify zero diff on the RRAS connection before applying.
4. If Meraki says the issue is on the OCI/OCI-DRG side → escalate to Oracle support with LLD §2.2 identifiers and the same diagnostic timeline.

### 4.3 If Meraki TAC doesn't respond / case stalls
- Consider whether `192.168.128.0/24`'s OCI reachability requirement can be met a different way in the interim (e.g. routing through BikoFW-SRX → `192.168.1.0/24` → RRAS's already-working tunnel, if BikoFW-SRX's routing/security policies allow it) — this would be a workaround, not a fix, and would need its own risk assessment before implementing.

---

## 5. Validation Checklist (once a fix is applied)

Run all of these before declaring the tunnel fixed — don't stop at the first green result, since Phase 1 alone has looked "fixed" before without Phase 2 actually working:

- [ ] `oci network ip-sec-tunnel list --ipsc-id <mx68-connection-ocid>` — both tunnels show `"status": "UP"` and `"is-esp-established": true`
- [ ] Meraki `GET .../appliance/vpn/statuses` — `reachability` is no longer `"unknown"` for either peer
- [ ] **Regression check**: re-run the same command against the RRAS connection OCID — confirm both its tunnels are still `UP` with IKE+ESP established
- [ ] Let it sit for at least 10-15 minutes and re-check — confirm the tunnel stays up rather than flapping
- [ ] From a host on `192.168.128.0/24`, confirm actual reachability to something in `10.0.0.0/16` (not just tunnel status)

---

## 6. Rollback

No destructive changes are currently pending. If a future fix attempt needs to be rolled back:

- **OCI Terraform changes**: revert the file diff, re-run `terraform plan -target=` scoped to just the affected tunnel resources, apply.
- **Meraki peer config changes**: re-`PUT` the known-good baseline JSON from LLD §3.
- **BikoFW-SRX** (only if further changes are made there): `configure` → `rollback 1` → `commit` reverts instantly to the last committed config; a full config backup and Junos rescue snapshot from the 2026-07-06 change are also on file (session scratchpad + on-device rescue config) as a further-back fallback.

---

## 7. Sign-off Criteria

This project is complete when all items in §5 pass and remain stable for 24 hours, and the Meraki support case is closed with a documented root cause (add the root cause to `LLD-MX68-VPN.md` §5 once known, for future reference).
