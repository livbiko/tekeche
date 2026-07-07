# Rollback Procedures

## Automatic Rollback (scripts)

```powershell
cd C:\inetpub\wwwroot\tekeche\ops\scripts

.\Invoke-Rollback.ps1 -Latest        # Most recent recovery point
.\Invoke-Rollback.ps1                # Interactive selection
.\Invoke-Rollback.ps1 -PointId "ID" # Specific point
```

## Trigger Conditions for Immediate Rollback

Roll back immediately if ANY of the following occur after a change:

| Condition | Detection |
|-----------|-----------|
| Build fails | `pm2 status` shows errored |
| API health fails | `GET /health` returns non-200 |
| Booking flow broken | `Test-Build.ps1` fails |
| Authentication broken | OTP send/verify returns 5xx |
| Database unreachable | health.db ≠ 'connected' |
| Runtime crashes | Error log shows uncaughtException |
| Driver dispatch fails | `findNearbyDrivers` returns 0 despite online drivers |

## Rollback Decision Tree

```
Change deployed
     │
     ▼
Run Test-Build.ps1
     │
  ┌──┴──┐
PASS   FAIL
  │      │
Mark    Invoke-Rollback.ps1 -Latest
KnownGood  │
           ▼
       Run Test-Build.ps1 again
           │
        ┌──┴──┐
      PASS   FAIL
        │      │
     Incident  Manual recovery
     resolved  (see RECOVERY.md)
```

## What Gets Restored

| Component | How Restored |
|-----------|-------------|
| API code | `git reset --hard <commit>` |
| npm packages | Restored from git (package-lock.json) |
| Database | `mongorestore --drop` from dump |
| PM2 process | `pm2 reload tekeche-api --update-env` |
| Mobile app | Not auto-restored (OTA or store update required) |
| Environment | Not restored (secrets excluded from recovery points) |

## Time-to-Recovery Targets

- API code + DB: **< 5 minutes**
- Full verification: **< 10 minutes**

## Post-Rollback Checklist

After any rollback:

- [ ] `Test-Build.ps1` passes all checks
- [ ] Driver app can connect and go online
- [ ] Passenger app can request a ride
- [ ] PM2 shows `tekeche-api` as `online`
- [ ] No errors in `C:\logs\tekeche-api-error-7.log`
- [ ] Log incident in `MAINTENANCE_LOG.md`
