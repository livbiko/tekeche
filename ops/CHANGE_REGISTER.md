# Change Register

One entry per change request (process: `CHANGE_APPROVAL.md`). Newest first. Status: requested / approved /
done / rolled back / rejected / EMERGENCY.

| CR | Title | Requested by | Class | Approved (owner's words, time UTC) | Window | Status |
|---|---|---|---|---|---|---|
| CR-2026-11-16-09 | Tekeche MongoDB backups copied off-site to OCI Object Storage (replaces CR-08 step 2) | owner ("c, write the CR") | HIGH (Get-ChangeRisk) | — | proposed: now, 45 min | requested |
| CR-2026-11-16-08 | Tekeche MongoDB backups: hourly, copied to BIKODC1, freshness check (option B) | owner ("B now, write the CR") | HIGH (Get-ChangeRisk) | — | proposed: now, 45 min | requested |
| CR-2026-11-16-07 | NDP: reject gambling candidates 144 and 524 (admin UI/API) | Claude | MEDIUM (Get-ChangeRisk) | "approve CR-2026-11-16-07" ~16:34 | 16:35-16:41 | done |
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

### CR-2026-11-16-09  Tekeche MongoDB backups copied off-site to OCI Object Storage
- Requested by: owner, 11-16 ("c, write the CR"). Replaces CR-08 step 2 (copy to BIKODC1: SYSTEM got Access denied on
  `\\192.168.1.102\c$`; nothing was created there).
- Today (after CR-08): `Tekeche-MongoDB-Backup` runs hourly at :10 on BIKODC -> `C:\backups\tekeche\<timestamp>`
  (26 `.json.gz`, ~1.3 MB), 14 days kept. Only copy is on BIKODC (same ESXi host as .53 unless the owner says otherwise).
- What changes:
  1. OCI (tenancy lr14abpkfrxj, region uk-london-1, the CLI profile already on BIKODC): a new **private** bucket
     `tekeche-mongo-backups` (no public access, Oracle-managed encryption, Standard tier), with a lifecycle rule that
     deletes objects older than **30 days**. Compartment: the Tekeche compartment if one exists, else the tenancy root
     (where the only bucket today, bucket-20260523-2129, is) - recorded at apply.
  2. New script `ops\scripts\Copy-TekecheBackupOci.ps1` + task `Tekeche-Backup-Offsite` (hourly at :25, SYSTEM, same as the
     backup task): uploads each backup folder not yet uploaded to `tekeche/<timestamp>/<collection>.json.gz` with
     `oci os object bulk-upload --no-overwrite` and the existing CLI config passed explicitly (`--config-file`); checks the
     object count matches the folder; appends one line per run to `C:\backups\tekeche\offsite.log`; exits non-zero on any
     failure. No keys or passwords in the script.
  3. Test-Build: the CR-08 backup check also requires the newest folder to be listed in the bucket.
- Why: a copy that survives losing BIKODC or the whole ESXi host; worst-case loss stays ~1 h.
- Class: HIGH (Get-ChangeRisk 11-16 ~17:00).
- Impact / downtime: none for users. ~1.3 MB upload per hour; ~1 GB kept in the bucket after 30 days (cost: within the
  free Object Storage allowance or a few pence a month).
- Risks / owner points:
  - The backups hold personal data (users, phone numbers, bookings). They leave the building, stored in OCI London,
    private, encrypted at rest by Oracle. If you want them also encrypted before upload (key kept on-prem), say so -
    that is a bigger change.
  - SYSTEM must be able to read the CLI config and API key (`C:\tekeche-ops\oci\...`); if it cannot, the script stops
    and that access change comes back for approval.
  - The API key used is the existing one (its user's rights decide whether it can create the bucket); if refused,
    the owner creates the bucket in the OCI console.
- Rollback: unregister `Tekeche-Backup-Offsite`; `git revert` of the script/Test-Build commit. The bucket and objects
  are left (deleting them only on owner request).
- Recovery point: Tekeche New-RecoveryPoint + export of the task list.
- Checks after: run the upload by hand -> objects for the newest backup in the bucket, count 26, sizes match; second run
  uploads nothing new (no duplicates); download one object and gunzip it to prove it reads; bucket is not public
  (`public-access-type NoPublicAccess`); lifecycle rule shown; Test-Build passes; the next :25 run succeeds.
- Window (proposed): now, 45 minutes.
- Approval: needs "approve CR-2026-11-16-09 window now" (or another time).

### CR-2026-11-16-08  Tekeche MongoDB backups: hourly, copied to BIKODC1, freshness check (option B)
- Requested by: owner, 11-16 ("B now, write the CR"), after the finding that Tekeche production runs on one standalone
  MongoDB 4.4.31 on dr-mongo 192.168.1.53 (no replica set since 09-13). Option A (new replica set) stays a later project.
- Today: scheduled task `Tekeche-MongoDB-Backup` on BIKODC runs `tekeche-api\scripts\backup.js` once a day at 01:00
  (JSON export of every collection from the .env URI, gzip, `C:\backups\tekeche\<timestamp>`, keeps 14 days; 26
  collections, ~1.4 MB/run, 19 MB total). Only copy is on BIKODC. Restore: `scripts\restore.js`. Worst case today: up to
  24 h of bookings/users lost, and losing BIKODC loses the backups too.
- What changes (BIKODC + BIKODC1 only; nothing on .53, tekeche-api, PM2, IIS, .env):
  1. Task `Tekeche-MongoDB-Backup`: trigger daily 01:00 -> **every hour** (at :10). Same script, same 14-day pruning
     (~336 copies, ~470 MB on C:). backup.js unchanged.
  2. New script `ops\scripts\Copy-TekecheBackup.ps1` + task `Tekeche-Backup-Copy` (hourly at :25): copies new backup
     folders to `\\192.168.1.102\c$\backups\tekeche-copy` (BIKODC1), checks each copied folder has the same files and
     sizes, keeps 14 days there, logs one line per run to `copy.log`. Runs as the same account as the existing tasks.
  3. Test-Build.ps1: new check "Tekeche backup fresh": newest `C:\backups\tekeche` folder < 2 h old with >= 20
     `.json.gz` files, and the same folder present on BIKODC1.
- Why: cuts the worst-case data loss from ~24 h to ~1 h and keeps a copy off BIKODC until a replica set exists.
- Class: HIGH (Get-ChangeRisk 11-16 ~16:50).
- Impact / downtime: none for users. An hourly read of ~1.4 MB from .53 (seconds). ~470 MB disk on each of BIKODC and
  BIKODC1.
- Risks: the hourly export runs while bookings are written (each collection is read separately, so a backup is not
  a single point-in-time snapshot - same as today's nightly one); BIKODC1 share/permissions may need fixing (if the
  copy cannot write there, step 2 stops and comes back as its own decision).
- To confirm by owner: is BIKODC1 on a different physical host than BIKODC and .53? If it is the same ESXi host, the
  copy protects against losing the BIKODC VM, not the host.
- Rollback: task trigger back to daily 01:00 (exported to `ops\recovery-points\...\Tekeche-MongoDB-Backup.xml` before
  the change); unregister `Tekeche-Backup-Copy`; `git revert` of the script/Test-Build commit. Copies on BIKODC1 kept
  (deleting them only on an owner-approved list).
- Recovery point: Tekeche New-RecoveryPoint (fixed by CR-06) + export of the existing task XML.
- Checks after: run the backup task once by hand -> new folder, 26 files; run the copy task -> same folder on BIKODC1,
  identical file sizes, copy.log line; Test-Build passes with the new check; next two scheduled runs (:10 and :25)
  succeed (LastTaskResult 0).
- Window (proposed): now, 45 minutes.
- Approval: needs "approve CR-2026-11-16-08 window now" (or another time).

### CR-2026-11-16-07  NDP: reject gambling candidates 144 and 524
- Requested by: Claude (follow-up of CR-05).
- What changes: 2 rows in NDP `creators`, through `PATCH /api/admin/creators/:id` in the owner's logged-in /admin
  session (no direct SQL): review_status candidate -> **rejected**, reviewer_note (was empty) -> "Rejeté : chaîne de
  jeux d'argent / paris (CR-2026-11-16-07)". Nothing else on the rows changes.
  - 144 tunisien-casino-streamer-letsgivetaspin "TUNISIEN-CASINO STREAMER - LETSGIVETASPIN" (country 47 = TN,
    @tunisien-casinostreamer, from job 79)
  - 524 1xbet-philippines "1XBET Philippines" (no country, Southeast Asia, @1xbetph, bio "Official YouTube channel of
    1XBET Philippines. High Stakes High Reward!", from job 198)
- Why: gambling channels are not creators for the directory; CR-05 stops new ones, these two came in before it.
- Class: MEDIUM (Get-ChangeRisk 11-16 ~16:40, wording: "mark 2 creator candidates (gambling channels) as rejected with a
  reviewer note via the admin UI"). No window needed.
- Impact: none public (candidates are never shown); the review queue drops by 2. A rejected channel is "known", so
  discovery will not add it again.
- Rollback: PATCH both back to review_status candidate, reviewer_note "" (values recorded above).
- Checks after: GET /api/admin/creators/144 and /524 show rejected + note; public /api/creators unchanged (25).
- When: any time after approval, ~10 minutes, owner logged in to /admin in the automated Chrome tab.
- Recovery point: NDP New-RecoveryPoint before.
- Approval: "approve CR-2026-11-16-07" (owner, 11-16 ~16:34 UTC).
- Result: NDP recovery point dump 2026-11-16T16-35-45Z; PATCH 16:39:44 both 200, read back rejected + note; public
  /api/creators 25; Test-Build 8/8; Set-KnownGood (NDP registry #263). Correction: 524 already had a note
  ("Suggestion : rejeter (paris sportifs) - détecté sur le nom, à confirmer"), not empty - that is its rollback value. Done.

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
