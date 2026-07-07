# Tekeche Recovery Guide

## Single-Command Recovery

```powershell
cd C:\inetpub\wwwroot\tekeche\ops\scripts

# Restore the most recent recovery point
.\Invoke-Rollback.ps1 -Latest

# Restore a specific point (interactive list)
.\Invoke-Rollback.ps1

# Restore a specific point by ID
.\Invoke-Rollback.ps1 -PointId "2026-06-28_13-00-00_description"
```

## Recovery Point Locations

All recovery points are stored in:
```
C:\inetpub\wwwroot\tekeche\ops\recovery-points\
```

Each point contains:
- `metadata.json` — timestamp, description, commit hashes, rollback instructions
- `git-state.txt` — branch, commit, working tree status
- `package-versions.json` — exact dependency versions
- `env-keys.txt` — environment variable names (no values)
- `db-dump\` — full mongodump of the tekeche database

## Creating a Recovery Point

```powershell
.\New-RecoveryPoint.ps1 `
  -Description "Before adding new payment provider" `
  -Reason "Integrating CinetPay API" `
  -FilesAffected @("src/services/payment.service.js", ".env") `
  -ExpectedImpact "Medium" `
  -RollbackInstructions "Revert payment service, remove env vars, reload pm2"
```

## Partial Recovery Options

```powershell
# Restore only the database (keep current code)
.\Invoke-Rollback.ps1 -PointId "..." -DbOnly

# Restore only code (keep current database)
.\Invoke-Rollback.ps1 -PointId "..." -CodeOnly
```

## Manual Recovery (if scripts fail)

### 1. Restore code
```powershell
git -C C:\inetpub\wwwroot\tekeche\tekeche-api reset --hard <commit-hash>
pm2 reload tekeche-api --update-env
```

### 2. Restore database
```powershell
& "C:\Program Files\MongoDB\Tools\100\bin\mongorestore.exe" `
  --uri "mongodb://tekeche:<pass>@127.0.0.1:27017/tekeche" `
  --db tekeche `
  C:\inetpub\wwwroot\tekeche\ops\recovery-points\<point-id>\db-dump\tekeche `
  --drop
```

### 3. Verify recovery
```powershell
.\Test-Build.ps1
```

## Known Good Builds

See `KNOWN_GOOD_BUILDS.json` for all verified production-safe builds.

```powershell
# List known good builds
Get-Content C:\inetpub\wwwroot\tekeche\ops\KNOWN_GOOD_BUILDS.json | ConvertFrom-Json | Format-Table buildNumber, dateCreated, apiCommit, note
```

## Change Risk Assessment

Before any change, check its risk level:
```powershell
.\Get-ChangeRisk.ps1 -Change "Description of what you want to change"
```

| Risk   | Recovery Point | Approval | Maintenance Window |
|--------|---------------|----------|--------------------|
| Low    | Not required  | Yes      | No                 |
| Medium | Required      | Yes      | No                 |
| High   | Required      | Yes      | Yes — mandatory    |

## Emergency Contacts

- PM2 process manager: `pm2 status`, `pm2 logs tekeche-api`
- MongoDB: `mongosh mongodb://tekeche:<pass>@127.0.0.1:27017/tekeche`
- IIS: `iisreset /restart` (last resort)
- Logs: `C:\logs\tekeche-api-out-7.log`, `C:\logs\tekeche-api-error-7.log`
