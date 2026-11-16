# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
| CR-2026-11-16-06 | Tekeche New-RecoveryPoint: dump the production MongoDB (.53) and fail loudly | Claude | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-06" + "approve CR-2026-11-16-06 window now" ~16:28 | 16:28-16:33 | done (Build #64) |
| CR-2026-11-16-05 | NDP creator discovery: skip gambling/betting channels (worker build) | Claude | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-16-05" ~15:30 | 15:32-16:03 | done (worker a1952d25) |
| CR-2026-11-16-04 | Approve 3 Côte d'Ivoire creators (515-517) | owner decision ("Approve all 3") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-04" ~13:33 | 13:35-13:45 | done |
| CR-2026-11-16-03 | Add 3 Côte d'Ivoire creator candidates (NDP admin API) | Claude (owner asked "go 3") | HIGH (Get-ChangeRisk) | "approve CR-2026-11-16-03" ~13:00 | 13:04-13:2x | done (creators 515-517, candidates) |
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

### CR-2026-11-16-06  Tekeche New-RecoveryPoint: dump the production MongoDB and fail loudly
- Requested by: Claude (found 11-16 while doing CR-05).
- Finding (read-only checks 11-16 16:10-16:20): `ops/scripts/New-RecoveryPoint.ps1` dumps `127.0.0.1:27017` (BIKODC's
  own mongod). That node answers hello with no set name, not primary, not secondary, so mongodump fails
  ("NotPrimaryOrSecondary"). The script hides the error (`| Out-Null`) and then crashes on `.Sum`. Recovery points
  2026-11-05_01-00-43 and 2026-11-16_15-32-42 have **empty** db-dump folders (up to 10-18 they were ~11 MB).
  Production tekeche-api (.env, unchanged since 09-13) uses a **standalone** mongod on 192.168.1.53 (hello: no set
  name, writable primary); /health ok on :5000 and api.tekeche.com. The nightly `Tekeche-MongoDB-Backup` task
  (backup.js, uses the .env URI) is fine: 2026-11-16T01-00-03, 1.4 MB, all collections.
- What changes: New-RecoveryPoint.ps1 and Invoke-Rollback.ps1 read MONGODB_URI from `tekeche-api\.env` instead of a
  hard-coded 127.0.0.1 URI (no password in the script any more); mongodump errors are shown and stop the script
  (no recovery point is reported as created without a database dump); the dump size is checked (> 0).
  Test-Build.ps1's Mongo check reviewed for the same hard-coded URI.
- Not in this CR: Tekeche MongoDB has no replica set / failover (standalone on .53 since 09-13), and BIKODC's mongod
  is in a dead replica-set state - owner decision needed, separate HIGH CR if a fix is wanted.
- Class: HIGH (Get-ChangeRisk 11-16 ~16:35; Claude had written MEDIUM). Needs an approved window.
- Impact: none on users. mongodump of .53 reads ~11 MB.
- Rollback: `git revert` of the script commit.
- Checks after: New-RecoveryPoint -Description "CR-06 test" produces a non-empty db-dump; a forced bad URI makes it
  stop with an error; Test-Build (Tekeche) passes.
- Recovery point: the script being fixed cannot dump the DB, so: git state of ops/scripts (commit before the change)
  + the nightly Tekeche-MongoDB-Backup of 2026-11-16 01:00 (1.4 MB). The change does not write to MongoDB.
- Window (proposed): now, 30 minutes, after "approve CR-2026-11-16-06 window now".
- Approval: "approve CR-2026-11-16-06", then (after Get-ChangeRisk said HIGH) "approve CR-2026-11-16-06 window now"
  (owner, 11-16 ~16:28 UTC).
- Result: d59c11d. Test 1: recovery point 2026-11-16_16-29-56 = 26 collections / 10 MB from .53. Test 2: script copy
  with a 127.0.0.1 URI stops at the dump, exit 1, nothing reported created. Test 3: Test-Build 9/9. Set-KnownGood
  Build #64. Invoke-Rollback's restore now also fails loudly (not exercised - it would overwrite production).
  Note: the old password stays in git history of these scripts (rotation = owner decision). Done.

### CR-2026-11-16-05  NDP creator discovery: skip gambling/betting channels
- Requested by: Claude (11-16, after reviewing discovery job results).
- What changes: nouvellesdupays `apps/worker/src/creator-agents.js` `runDiscoverJob`: a new rejection reason
  `gambling` (added to REJECTIONS and the job log line), checked on channel title + handle + description with
  `/(1xbet|casino|betting|bookmaker|paris sportifs?|jackpot|\bslots\b|sportsbook)/i`. Plain "bet" is NOT matched
  (read-only check 11-16: it would wrongly catch candidate 113 "Beto Dias Official"). A unit test for both cases.
  Worker image rebuild (Kaniko, from GitHub main) + rollout, as earlier worker builds.
  Not in this CR: corporate brands (KFC, Pantene, Riyadh Air...) - no reliable rule; existing junk candidates stay
  as they are (rejecting them would be a separate CR, done in /admin/creators).
- Why: candidates 144 "TUNISIEN-CASINO STREAMER" and 524 "1XBET Philippines" were added by discovery; gambling
  channels must never reach the review queue. Queue on 11-16: 549 candidates, 136 without a country.
- Class: MEDIUM (feature change in a worker; Get-ChangeRisk to be run alone before apply).
- Impact / downtime: worker restart only (no reader-facing downtime); discovery adds slightly fewer candidates.
- Rollback: `rollout undo`/set image to the rollback tag of the current worker (f14f7de2) recorded before the build.
- Checks after: worker tests pass (CI pod); worker pod Running on the new digest; next discovery job's result shows a
  `gambling` count; Test-Build.
- Recovery point: New-RecoveryPoint before.
- Approval: "approve CR-2026-11-16-05" (owner, 11-16 ~15:30 UTC).
- Result: Get-ChangeRisk MEDIUM; NDP recovery point 2026-11-16_15-33-18 (full); commit f75946e pushed (ls-remote
  checked); worker tests 115/115; rollback tag rollback-f1869de6 (live worker was f1869de6, not f14f7de2 as noted
  earlier); job b263-worker -> a1952d25, new code checked in the image; worker run 29914080 Succeeded 16:00;
  Test-Build 8/8; Set-KnownGood (registry #262). Deviation: Claude first ran the Tekeche New-RecoveryPoint by mistake
  - it created a partial folder (its MongoDB dump produced nothing and the script crashed); no change resulted (see
  CR-06). Done. creator-agents 16:25 ran on a1952d25 (Succeeded) but YouTube quota was spent (75 units left, 10 jobs
  waiting), so the filter has not met a real job yet.

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
- Approval: "approve CR-2026-11-16-03" (owner, 11-16 ~13:00 UTC).
- Result: recovery point 2026-11-16_13-04-24; added through the admin API in the owner's session: 515
  le-samourai-thea (account 1696), 516 franklin-nyamsi (1697), 517 bantu-media-authentique (1698), all
  candidate / REQUIRES_REVIEW / CI / fr with the reviewer note; public /api/creators still 22, no CI creator. Done.

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

### CR-2026-11-16-04  Approve 3 Côte d'Ivoire creators
- Requested by: owner decision 11-16 ("Approve all 3"), written up by Claude.
- What changes: creators 515 Le Samouraï Théa, 516 Franklin Nyamsi, 517 Bantu Media Authentique (CI): confidence
  REQUIRES_REVIEW -> PROVISIONAL, a reviewer-decision evidence row each (note "Décision du propriétaire 2026-11-16
  (CR-2026-11-16-04) - chaîne YouTube enregistrée hors CI"), review_status candidate -> approved. Through the admin
  API in the owner's session, as Builds #254/#257.
- Why: brief section 3 names them for Côte d'Ivoire; owner decided they count for CI although their channels are
  registered in MA / US / SN.
- Class: HIGH (Get-ChangeRisk; the same kind of approval was MEDIUM for #254/#257 with other wording). Window below.
- Impact: they become public at /creators/<slug> as "sélectionné par la rédaction (identité non vérifiée)"; CI goes
  to 3 approved (5 needed for /youtube/cote-divoire). Ranked at the next daily ranking run.
- Rollback: reverse.sql (back to candidate / REQUIRES_REVIEW, delete the 3 evidence rows), rehearsed before.
- Checks after: admin API shows approved/PROVISIONAL; public /api/creators 25 incl. 3 CI; profile pages 200; Test-Build.
- Window: now, 10 minutes (owner logged in to /admin).
- Approval: "approve CR-2026-11-16-04" (owner, 11-16 ~13:33 UTC).
- Result: recovery point 2026-11-16_13-35-38; 515/516/517 approved PROVISIONAL, evidence 38/39/40; public
  /api/creators 25 (3 CI), the 3 profile pages 200; Test-Build 8/8. Deviation: reverse.sql
  (nouvellesdupays ops/release-creators-approve-ci) was written and rehearsed AFTER the apply, not before as the CR
  said - rehearsal OK (3 rows each, rolled back). Done.
