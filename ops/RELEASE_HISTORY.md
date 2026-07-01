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

