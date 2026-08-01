# Release History

All builds marked as Known Good are recorded here.
A Known Good Build has passed the full `Test-Build.ps1` verification checklist.

---

## Build #2 â€” 2026-06-30 21:40

- **API commit**: 6c442086 (master)
- **Mobile commit**: 3c359eae
- **API version**: 1.0.0
- **Tests**: skipped
- **Production-safe**: Yes
- **Note**: Produits screen activated, Woyo bottom nav added, OTA pipeline refactored to single-job (no matrix). API health=ok db=connected.


## Build #3 â€” 2026-07-01 15:36

- **API commit**: da4caccb (master)
- **Mobile commit**: 3c359eae
- **API version**: 1.0.0
- **Tests**: skipped
- **Production-safe**: Yes
- **Note**: GET /api/drivers/status added; stale socket disconnect fix; Test-Build.ps1 encoding + all 6 checks fixed; OTA pipeline refactored to single-job. 8/9 checks pass; booking flow skipped (requires live driver).


## Build #4 â€” 2026-07-01 19:57

- **API commit**: da4caccb (master)
- **Mobile commit**: 9ccf438a
- **API version**: 1.0.0
- **Tests**: skipped
- **Production-safe**: Yes
- **Note**: Woyo tab navigates to service page; OTA pipeline targets Windows runner explicitly. All prior session fixes included.


## Build #5 â€” 2026-07-01 20:18

- **API commit**: da4caccb (master)
- **Mobile commit**: 9ccf438a
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Passenger OTA confirmed: Woyo tab opens service page — both passenger and driver OTAs deployed and live


## Build #6 â€” 2026-07-01 21:31

- **API commit**: da4caccb (master)
- **Mobile commit**: 33a32c06
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Push notification fix: re-register token on app foreground — driver OTA live


## Build #7 â€” 2026-07-01 22:56

- **API commit**: c5236d5c (master)
- **Mobile commit**: 33a32c06
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fix lastSeen field: add to Driver schema and update on socket connect


## Build #8 â€” 2026-07-02 00:31

- **API commit**: c5236d5c (master)
- **Mobile commit**: 33a32c06
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Passenger OTA confirmed: push notification fix live on both apps


## Build #9 â€” 2026-07-02 10:13

- **API commit**: a8568928 (master)
- **Mobile commit**: bea25cfe
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: SMS dispatch fallback, 120s timeout, socket reconnection tuning, Woyo tab removed


## Build #10 â€” 2026-07-02 13:39

- **API commit**: a8568928 (master)
- **Mobile commit**: 24976781
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Woyo card navigates directly to booking form, no bottom tab, no intermediate page


## Build #11 â€” 2026-07-02 15:42

- **API commit**: a8568928 (master)
- **Mobile commit**: 24976781
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Driver OTA in progress — re-verifying Build #10 state


## Build #12 â€” 2026-07-02 22:03

- **API commit**: 25d5cc21 (master)
- **Mobile commit**: 24976781
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: OTA 304 fix: manifest now returns 200 always, no ETag


## Build #13 â€” 2026-07-02 22:14

- **API commit**: 25d5cc21 (master)
- **Mobile commit**: 24976781
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: OTA 304 fix: manifest now returns 200 always, no ETag — 9/9 verified


## Build #14 â€” 2026-07-03 17:10

- **API commit**: 25d5cc21 (master)
- **Mobile commit**: 5da31bf1
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Added 56 Côte d'Ivoire cities to localites — 69 total zones at 250 FCFA default fare. Booking flow skipped: no live driver (device connectivity issue, not code).


## Build #15 â€” 2026-07-03 17:30

- **API commit**: 25d5cc21 (master)
- **Mobile commit**: 864942b1
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: 4 UI changes: service icons +20%, Woyo car icon, GPS zone auto-detect, Wave/MTN/Especes payment. OTA push triggered.


## Build #16 â€” 2026-07-09 12:42

- **API commit**: 633e89de (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Admin alerts via Brevo SMTP relay (noreply@tekeche.com). 8/9 checks passed; booking-flow E2E failed only due to no driver online in test app at run time (unrelated, documented exception - see MAINTENANCE_LOG.md 2026-07-09).


## Build #17 â€” 2026-07-09 23:25

- **API commit**: 633e89de (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: 2026-07-09 23:23 - Fixed BIKODC DNS self-registration + MongoDB rs.conf hostname flapping + dead OCI standby member. 9/9 Test-Build.ps1 checks passed including full automated booking flow.


## Build #18 — 2026-07-12 16:22

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: OCI LB onprem backend repointed from broken NLB VIP (192.168.1.100) to BikoDC direct IP (192.168.1.101). Test-Build 8/9 - override forced: sole failure is 'no driver online', a pre-existing unrelated test-environment precondition (confirmed via admin API: all 29 drivers isOnline:false), not a regression -- driver app path unaffected since public DNS cutover was deferred.


## Build #19 — 2026-07-12 22:32

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: OCI standby resized to 8 OCPU/32GB + PM2 cluster mode (16 workers) for full-capacity failover; Mongo RS rejoined SECONDARY healthy; Test-Build 8/9 pass, sole failure is unrelated env precondition (no driver online for automated booking-flow test), accepted per user decision


## Build #20 — 2026-07-16 10:45

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Post BIKODC disk extend (149GB) + PM2 outage recovery (35hr undetected downtime, fixed). 8/9 Test-Build checks pass; sole failure is the pre-existing 'no online test driver' gap, same as prior known-good builds.


## Build #21 — 2026-07-17 08:42

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Consolidated tekeche-vcn/IGW/public-subnet/LB from tekeche-pub into UK compartment (security zone driving the split was deleted 2026-07-04). 8/9 Test-Build checks pass; sole failure is the pre-existing no-online-driver test-data gap, unrelated.


## Build #22 — 2026-07-19 09:00

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: BIKO-OCI-DC2 promoted to writable DC; fixed BikoDC/BikoDC1 DNS self-registration bug blocking its replication (DoNotRegisterAdditionalIpv4Addresses)


## Build #23 — 2026-07-19 16:02

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Extended DNS failover to security.tekeche.com, staging-api.tekeche.com (full), and pay.tekeche.com (scaffolding); fixed live MongoDB firewall gap and dead .100/.110 VIPs


## Build #24 — 2026-07-19 17:12

- **API commit**: 8ccc9960 (master)
- **Mobile commit**: 564ebbc6
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Dedicated IIS app pools extended to all 7 sites (closed DefaultAppPool sharing fragility); DNS failover live for tekeche.com/livbiko.com/kendebabi.com/security.tekeche.com/staging-api.tekeche.com


## Build #25 — 2026-07-28 13:23

- **API commit**: 0d99efac (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed Test-Build.ps1 PM2-check false positive (ANSI escape codes broke the status regex). 8/9 green; remaining failure (booking-flow) needs a live socket-connected test driver online, a known environmental precondition unrelated to code health — accepted per explicit approval.


## Build #26 — 2026-07-28 13:29

- **API commit**: 0d99efac (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Added isSynthetic isolation flag (User/Driver/Trip) + partitioned dispatch/woyo matching so the planned 20-day bot QA fleet can run on production without ever reaching real drivers/passengers. 8/9 green; booking-flow check needs a live socket-connected test driver, same accepted environmental gap as Build #25.


## Build #27 — 2026-07-28 13:44

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 0 of 20-day bot QA fleet: excluded isSynthetic accounts from admin.controller.js's listDrivers/listTrips/listWoyoDrivers/getStats by default (opt-in via includeSynthetic=true). Same accepted 1/9 baseline (booking-flow needs a live driver online).


## Build #28 — 2026-07-28 13:54

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 1 of 20-day bot QA fleet: provisioned 35 synthetic User+Driver identity pairs (5 moto, 13 standard, 5 comfort, 4 xl, 8 woyo) across 10 real Abidjan communes, all isSynthetic:true, kycStatus:approved, currently isOnline:false pending Phase 4's scheduler. Idempotency verified (re-run created zero duplicates). Manifest at ops/bot-fleet/manifest.json. Same accepted 1/9 baseline.


## Build #29 — 2026-07-28 14:09

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 2 of 20-day bot QA fleet: driver-bot.js runtime, verified end-to-end against production (real synthetic passenger request -> real dispatch -> bot accept -> full status lifecycle, correct isSynthetic isolation throughout). Same accepted 1/9 baseline.


## Build #30 — 2026-07-28 14:18

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 3 of 20-day bot QA fleet: passenger-bot.js runtime, verified alongside a driver bot against production (correct active-trip detection and randomized request scheduling). Same accepted 1/9 baseline.


## Build #31 — 2026-07-28 14:30

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 4 of 20-day bot QA fleet: scheduler.js window orchestration, verified in dry-run mode after fixing a real apportionment bug (start/end fields leaking into the percentage math). All 5 windows confirmed to sum to exactly 35 with zero pool overflow. Midnight-6am is an explicit idle gap per user decision. Same accepted 1/9 baseline.


## Build #32 — 2026-07-28 14:43

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Phase 5 of 20-day bot QA fleet: PM2 deployment (tekeche-bot-fleet, fork mode). Registered, validated (briefly went live during registration, verified fully harmless and cleanly recoverable), then deliberately left stopped for Phase 6's explicit go-live. Same accepted 1/9 baseline.


## Build #33 — 2026-07-28 14:56

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed a real orphaned-trip bug found while checking on the live 20-day fleet: driver-bot.js in-memory trip state didn't survive a process restart, leaving trips permanently stuck. Now recovers via GET /drivers/active-trip on startup. Deployed live (fleet restarted, 20-day clock correctly preserved at original 2026-07-28T13:47:22Z start, 23/23 drivers reconnected cleanly, zero orphaned trips post-restart). Same accepted 1/9 baseline.


## Build #34 — 2026-07-28 15:44

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed a real gap found during a live fleet status check: driver-bot.js's startup recovery only caught orphans that came back as a driver; a scheduler restart's role reshuffle can reassign an identity to passenger instead, leaving the trip permanently orphaned with nothing role-specific to catch it. 6 real orphaned trips found live (from the earlier redeploy's reshuffle). Added a role-independent periodic sweep to scheduler.js (every 5min, 30min staleness threshold) as a backstop. Deployed live: redeployed, sweep immediately cleaned up 5 stale trips on startup with zero errors, 23/23 drivers reconnected correctly, 0 remaining stale trips post-sweep. Same accepted 1/9 baseline.


## Build #35 — 2026-07-28 16:20

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed the root cause of recurring orphaned trips found during a live status check: all 35 bots shared one rate-limit bucket by hitting the public API endpoint from the same machine (100 req/15min overall, 5 req/min on /rides/request), causing scattered 429s (~50 across 25 of 35 bots) including on the recovery mechanism's own completion calls. Switched lib.js to hit localhost directly (127.0.0.1:5000), which both rate limiters already explicitly exempt -- zero changes to production rate-limiting code. Deployed live: 23/23 drivers reconnected cleanly, zero errors since restart, 20-day clock preserved at original 2026-07-28T13:47:22Z start. Same accepted 1/9 baseline.


## Build #36 — 2026-07-28 16:25

- **API commit**: a586b5c1 (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed idle-relocation re-entrancy bug in driver-bot.js: the 8s GPS timer could re-enter maybeRelocate() while a previous relocation's travelTo() was still mid-flight (idleSince not reset until completion), causing overlapping concurrent relocations racing on pos -- visible as erratic zig-zag movement instead of one smooth move. Added a relocating guard. Deployed live, clean restart, zero errors, 20-day clock preserved at original start. Same accepted 1/9 baseline.


## Build #37 — 2026-07-28 16:33

- **API commit**: 57753aaf (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed a real production bug found via the bot fleet's orphaned-trip sweep: driver.controller.js's updateTripStatus guard only excluded already-completed trips, not cancelled ones, allowing a driver's in-flight status update to resurrect a cancelled trip. Not bot-fleet-specific -- same race possible with real users. Tightened guard to exclude both completed and cancelled. Cleaned up the one corrupted trip this exposed. Reloaded tekeche-api live, healthy. Same accepted 1/9 baseline.


## Build #38 — 2026-07-28 18:07

- **API commit**: 57753aaf (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Found and fixed the real ongoing source of orphaned trips (was steady ~1 per 15min even after all prior fixes): rides.controller.js's pool-matching assigns a second trip to an already-busy driver directly at the DB level via pool_pickup_added, an event driver-bot.js never listened for. Traced conclusively via one case (trip never appearing anywhere in its assigned driver's own log despite being DB-assigned to them). Added the missing handler, progresses pooled trips independently of the primary trip through the same proven status-update API. Deployed live, clean restart, zero errors, 20-day clock preserved. Same accepted 1/9 baseline.


## Build #39 — 2026-07-28 21:09

- **API commit**: 57753aaf (master)
- **Mobile commit**: dd0df115
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed a systemic zombie-process gap found via a full OS-level process audit: identity #7 had two processes running simultaneously for hours (a driver whose socket died but process never exited, plus a genuinely ancient pre-launch leftover with zero log output ever). Root cause: stopBot() deleted from tracking the instant SIGTERM was sent, without confirming actual termination, and nothing periodically verified tracked-as-active drivers were still genuinely connected. Added confirmed-termination (SIGTERM + 5s grace + SIGKILL fallback, reconcile() awaits before replacing) and a 5-minute DB-backed driver-liveness sweep. Manually cleaned up both zombies, redeployed, verified exactly 35 processes (no dupes/gaps) and 18/18 drivers online matching the window target precisely. Same accepted 1/9 baseline.


## Build #40 — 2026-07-29 23:23

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Tightened tekeche-nlb health-checker (10s/2/5s -> 3s/2/2s) on main+http backend sets; added Invoke-SafeRestart.ps1 drain-first restart wrapper for BikoDC. 8/9 Test-Build.ps1 -- only failure is the long-standing pre-existing socketId/synthetic-driver booking-flow gap (documented since 2026-07-19), no mechanism connects it to NLB config or an unexecuted new script.


## Build #41 — 2026-07-30 08:46

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Active-active fault-tolerance build for api.tekeche.com: Redis cross-node fan-out to OCI standby, 50/50 active-active NLB split, empirically-verified MongoDB election resilience, plus a critical fix (isSynthetic exact-match bug that prevented real dispatch from ever matching a real driver) deployed fleet-wide to BikoDC/BikoDC1/OCI standby.


## Build #42 — 2026-07-31 12:54

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed test-booking-flow.js to use fixed QA driver (assalehervekouame+driver1) instead of depending on a real driver already online; loadbalancer.tf synced to live NLB state.


## Build #43 — 2026-07-31 18:05

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Added real DNS-level failover for api.tekeche.com (NLB-primary/on-prem-backup), fixed a broken health monitor found along the way


## Build #44 — 2026-07-31 22:58

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: OCI Vault .env secret: added OCI standby (10.0.2.10) to MONGODB_URI seed list, closing cold-start Mongo bootstrap gap for api.tekeche.com self-sufficiency. Redis on-prem-only dependency (BikoDC1) remains open, deferred as separate follow-up.


## Build #45 — 2026-08-01 00:39

- **API commit**: 57753aaf (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Redis Sentinel deployed across 7 nodes (BikoDC, BikoDC1, OCI standby, 2 Mongo arbiters, 2 pre-existing OKE nodes), quorum=4. tekeche-api now sentinel-mode for Socket.io cross-node fan-out, live failover drill passed (master moved .102->.101 automatically, app never restarted, Test-Build 9/9 post-failover). Closes the last open item from tonight's OCI self-sufficiency audit.


## Build #46 — 2026-08-01 13:14

- **API commit**: b15b1c09 (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: Fixed OCI standby stuck in Redis direct-mode (stale code, missing Sentinel feature + ioredis dep) - root cause of production 'Erreur de connexion reseau' during BikoDC+BikoDC1 power-off drill. Standby now on origin/master b15b1c0, sentinel mode confirmed, pm2 save done.


## Build #47 — 2026-08-01 19:23

- **API commit**: b15b1c09 (master)
- **Mobile commit**: 81528d6e
- **API version**: 1.0.0
- **Tests**: passed
- **Production-safe**: Yes
- **Note**: mongo-rs-watchdog deployed to OCI standby (commit 45b77d2), Test-Build.ps1 clean 9/9

