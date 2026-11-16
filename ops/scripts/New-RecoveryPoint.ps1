<#
.SYNOPSIS
    Creates a recovery point before any change to the Tekeche system.

.DESCRIPTION
    Snapshots git state, MongoDB, package versions, and env config shape.
    Run this before ANY medium or high-risk change.

.EXAMPLE
    .\New-RecoveryPoint.ps1 -Description "Before OTP rate limit increase" -Reason "Rate limit too strict for testers" -ExpectedImpact "Low"
#>
param(
    [Parameter(Mandatory)][string]$Description,
    [string]$Reason       = "",
    [string[]]$FilesAffected = @(),
    [string]$ExpectedImpact  = "Low",
    [string]$RollbackInstructions = "Run Invoke-Rollback.ps1 and select this point."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$MONGODUMP  = "C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe"
# Production MongoDB = MONGODB_URI in tekeche-api\.env (CR-2026-11-16-06: the hard-coded 127.0.0.1 URI pointed at
# BIKODC's own mongod, which is not the production database since 09-13 - recovery points had empty dumps).
$envLine = Get-Content "C:\inetpub\wwwroot\tekeche\tekeche-api\.env" | Where-Object { $_ -match '^MONGODB_URI=' } | Select-Object -First 1
if (-not $envLine) { throw "MONGODB_URI not found in C:\inetpub\wwwroot\tekeche\tekeche-api\.env" }
$MONGO_URI = ($envLine -replace '^MONGODB_URI=', '').Trim().Trim('"')
$API_DIR    = "C:\inetpub\wwwroot\tekeche\tekeche-api"
$MOB_DIR    = "C:\inetpub\wwwroot\tekeche\tekeche-mobile"
$OPS_DIR    = "C:\inetpub\wwwroot\tekeche\ops"
$HISTORY    = "$OPS_DIR\BACKUP_HISTORY.md"

$stamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$slug   = ($Description -replace '[^a-zA-Z0-9]', '-').ToLower() -replace '-+', '-'
$slug   = $slug.Substring(0, [Math]::Min($slug.Length, 40)).TrimEnd('-')
$ptDir  = "$OPS_DIR\recovery-points\$stamp`_$slug"

Write-Host "`n=== Creating Recovery Point ===" -ForegroundColor Cyan
Write-Host "Directory: $ptDir"
New-Item -ItemType Directory -Force $ptDir | Out-Null

# ── Git state ────────────────────────────────────────────────────────────────
Write-Host "  [1/5] Capturing git state..."
$apiBranch = git -C $API_DIR rev-parse --abbrev-ref HEAD 2>&1
$apiCommit = git -C $API_DIR rev-parse HEAD 2>&1
$apiStatus = git -C $API_DIR status --short 2>&1
$apiLog    = git -C $API_DIR log --oneline -5 2>&1

$mobBranch = git -C $MOB_DIR rev-parse --abbrev-ref HEAD 2>&1
$mobCommit = git -C $MOB_DIR rev-parse HEAD 2>&1

@"
=== tekeche-api ===
Branch : $apiBranch
Commit : $apiCommit
Status :
$($apiStatus | Out-String)

Recent commits:
$($apiLog | Out-String)

=== tekeche-mobile ===
Branch : $mobBranch
Commit : $mobCommit
"@ | Set-Content "$ptDir\git-state.txt" -Encoding UTF8

# ── Package versions ─────────────────────────────────────────────────────────
Write-Host "  [2/5] Capturing package versions..."
$apiPkg = Get-Content "$API_DIR\package.json" | ConvertFrom-Json
$mobPkg = Get-Content "$MOB_DIR\package.json" | ConvertFrom-Json
@{
    api = @{ name = $apiPkg.name; version = $apiPkg.version; dependencies = $apiPkg.dependencies }
    mobile = @{ name = $mobPkg.name; version = $mobPkg.version }
    capturedAt = (Get-Date -Format "o")
} | ConvertTo-Json -Depth 10 | Set-Content "$ptDir\package-versions.json" -Encoding UTF8

# ── Env config shape (keys only, no values) ──────────────────────────────────
Write-Host "  [3/5] Capturing env config shape..."
$envFile = "$API_DIR\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([A-Z_][A-Z0-9_]*)=') { $Matches[1] }
    } | Set-Content "$ptDir\env-keys.txt" -Encoding UTF8
}

# ── MongoDB dump ─────────────────────────────────────────────────────────────
Write-Host "  [4/5] Dumping MongoDB..."
$dbDumpDir = "$ptDir\db-dump"
New-Item -ItemType Directory -Force $dbDumpDir | Out-Null
$dumpErr = & $MONGODUMP --uri $MONGO_URI --out $dbDumpDir --quiet 2>&1
if ($LASTEXITCODE -ne 0) { throw "mongodump failed (exit $LASTEXITCODE): $("$dumpErr" -replace '(mongodb://[^:]+:)[^@]+@', '$1***@')" }
$dumpFiles = @(Get-ChildItem $dbDumpDir -Recurse -File)
$dumpSize = ($dumpFiles | Measure-Object Length -Sum).Sum
if ($dumpFiles.Count -eq 0 -or -not $dumpSize) { throw "mongodump wrote nothing to $dbDumpDir - recovery point NOT valid" }
Write-Host "        DB dump: $([Math]::Round($dumpSize/1KB, 1)) KB"

# ── Metadata ─────────────────────────────────────────────────────────────────
Write-Host "  [5/5] Writing metadata..."
$meta = @{
    id                   = "$stamp`_$slug"
    timestamp            = (Get-Date -Format "o")
    description          = $Description
    reason               = $Reason
    filesAffected        = $FilesAffected
    expectedImpact       = $ExpectedImpact
    rollbackInstructions = $RollbackInstructions
    apiCommit            = $apiCommit.ToString().Trim()
    apiBranch            = $apiBranch.ToString().Trim()
    mobileCommit         = $mobCommit.ToString().Trim()
    mobileBranch         = $mobBranch.ToString().Trim()
    dbDumpSizeKB         = [Math]::Round($dumpSize/1KB, 1)
}
$meta | ConvertTo-Json -Depth 5 | Set-Content "$ptDir\metadata.json" -Encoding UTF8

# ── Append to BACKUP_HISTORY.md ──────────────────────────────────────────────
$histEntry = @"

## $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") — $Description

- **ID**: $($meta.id)
- **Reason**: $Reason
- **API commit**: $($meta.apiCommit.Substring(0,8))  ($apiBranch)
- **Mobile commit**: $($meta.mobileCommit.Substring(0,8)) ($mobBranch)
- **Impact**: $ExpectedImpact
- **DB dump**: $([Math]::Round($dumpSize/1KB,1)) KB
- **Files affected**: $($FilesAffected -join ', ')
- **Rollback**: ``.\Invoke-Rollback.ps1 -PointId "$($meta.id)"``

"@
Add-Content $HISTORY $histEntry -Encoding UTF8

Write-Host "`n✅ Recovery point created: $($meta.id)" -ForegroundColor Green
Write-Host "   To restore: .\Invoke-Rollback.ps1 -PointId `"$($meta.id)`""
