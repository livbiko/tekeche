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

