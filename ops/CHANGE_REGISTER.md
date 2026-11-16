# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
| CR-2026-11-16-03 | Add 3 Côte d'Ivoire creator candidates (NDP admin API) | Claude (owner asked "go 3") | HIGH (Get-ChangeRisk) | — | proposed: now, 15 min | requested |
| CR-2026-11-16-02 | dr-haproxy: check for and delete leftover snapshot | Claude (owner asked) | HIGH | — | proposed: quiet hour, 20 min | requested |
| CR-2026-11-16-01 | Reset frozen dr-haproxy (all public sites down ~12:40-12:55) | owner / Claude | EMERGENCY (MEDIUM) | "logged in, reset it" 12:5x | — | done (service back 12:55; who reset it to be confirmed) |
| CR-2026-11-16-00 | Fraternité Matin feed time zone (label_time_zone Africa/Abidjan, 71 articles +2 h) | Claude | LOW | "approve 1" 12:1x | — | done 12:18 |

## Template

```
### CR-YYYY-MM-DD-NN  <title>
- Requested by:
- What changes (old -> new):
- Why:
- Class (Get-ChangeRisk):
- Impact / downtime:
- Rollback:
- Checks after:
- Window (HIGH):
- Approval (owner's words + time):
- Result:
```

### CR-2026-11-16-03  Add 3 Côte d'Ivoire creator candidates
- Requested by: Claude, after owner "approve 2a" (11-16) and "go 3".
- What changes: 3 new rows in NDP `creators` (review_status **candidate**, country CI, not public) + their YouTube
  account in `social_accounts`, through the admin API in the owner's logged-in session (no direct SQL):
  - Le Samouraï Théa — UCLtc8gGTaQzo__2_MBRbT2g (@thearobert8642), channel registered MA, 293k subscribers
  - Franklin Nyamsi — UCiQxANAElvyi0LubPBit8xw (@franklinnyamsi), registered US, 494k
  - Bantu Media Authentique — UCy5RkD0TDvDMwDtQNBs3tpQ (@bantumediaauthentique2097), registered SN, 115k
  Each with a reviewer note: "Brief section 3 named creator for Côte d'Ivoire; YouTube channel registered <XX>, not
  CI - owner to decide". "État d'Urgence": no matching channel found, not added.
- Why: brief section 3 names them as initial CI candidates; the discovery agent refuses channels registered abroad.
- Class: HIGH (Get-ChangeRisk; similar approvals #254/#257 rated MEDIUM with other wording).
- Impact / downtime: none; candidates are never shown publicly. No approval of any creator in this CR.
- Rollback: mark the 3 creators rejected in /admin/creators (or delete the rows they created; ids recorded at apply).
- Checks after: GET /api/admin/creators shows them as candidates with the note; public /api/creators unchanged (22).
- Window: now, about 15 minutes, once the owner is logged in to /admin.
- Recovery point: New-RecoveryPoint before.
- Approval: needs "approve CR-2026-11-16-03".

### CR-2026-11-16-02  dr-haproxy: check for and delete a leftover snapshot
- Requested by: Claude (owner asked to raise it, 11-16).
- What changes: ESXi VM dr-haproxy (vms/70, 192.168.1.50). Step 1 read-only: Manage snapshots, record what exists
  (name, date, size of delta). Step 2 only if a snapshot from 11-15 (~16:50 ESXi task clock) exists: Delete snapshot
  (ESXi merges the delta into the base disk; the VM keeps its current state).
- Why: dr-haproxy froze 11-14 and 11-16 (same signs: Tools not reporting, CPU 2.9 GHz, used space 5.96 -> 7.37 GB).
  A snapshot taken 11-15 then left in place grows a delta file and slows disk I/O; it is the main suspect.
- Class: HIGH (public entry point).
- Impact / downtime: none planned, but the merge is heavy disk I/O on a VM that freezes under I/O trouble: risk of
  a freeze during the merge = all public sites down until reset (as 11-14/11-16, ~15 min).
- Rollback: a deleted snapshot cannot be restored (the VM's current state is kept, only the old point in time is
  lost). If the VM freezes: ESXi Reset (EMERGENCY, section 5).
- Checks after: Recent tasks "Remove snapshot" completed; Manage snapshots empty; dr-haproxy answers; outside check of
  nouvellesdupays.com, tekeche.com, livbiko.com, 225woyo.com, kendebabi.com; NDP Test-Build; uptime-state "up".
- Window: a quiet hour (proposal: 03:00 UTC, 20 minutes), owner logged in to ESXi in the automated Chrome tab.
- Approval: needs "approve CR-2026-11-16-02 window <time>". Step 1 (read-only look) may happen any time.
