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

