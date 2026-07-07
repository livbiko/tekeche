<#
.SYNOPSIS
    Restores the Tekeche system to a previous recovery point.

.EXAMPLE
    .\Invoke-Rollback.ps1                          # Interactive — lists all points
    .\Invoke-Rollback.ps1 -PointId "2026-06-28_..."  # Direct rollback
    .\Invoke-Rollback.ps1 -Latest                  # Restore the most recent point
#>
param(
    [string]$PointId = "",
    [switch]$Latest,
    [switch]$DbOnly,
    [switch]$CodeOnly,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$MONGORESTORE = "C:\Program Files\MongoDB\Tools\100\bin\mongorestore.exe"
$MONGO_URI    = "mongodb://tekeche:6eY7EvTt57HM2dgmPgrsr64u@127.0.0.1:27017/tekeche"
$API_DIR      = "C:\inetpub\wwwroot\tekeche\tekeche-api"
$OPS_DIR      = "C:\inetpub\wwwroot\tekeche\ops"
$PTS_DIR      = "$OPS_DIR\recovery-points"

# ── List available points ────────────────────────────────────────────────────
$points = Get-ChildItem $PTS_DIR -Directory | Sort-Object Name -Descending
if ($points.Count -eq 0) { Write-Error "No recovery points found in $PTS_DIR"; exit 1 }

if ($Latest) { $PointId = $points[0].Name }

if (-not $PointId) {
    Write-Host "`nAvailable recovery points:" -ForegroundColor Cyan
    $i = 0
    foreach ($pt in $points) {
        $meta = Get-Content "$($pt.FullName)\metadata.json" | ConvertFrom-Json
        Write-Host "  [$i] $($meta.id)"
        Write-Host "      $($meta.description)"
        Write-Host "      API: $($meta.apiCommit.Substring(0,8)) | $($meta.timestamp)"
        $i++
    }
    $choice = Read-Host "`nEnter number to restore (or q to quit)"
    if ($choice -eq 'q') { exit 0 }
    $PointId = $points[[int]$choice].Name
}

$ptDir = "$PTS_DIR\$PointId"
if (-not (Test-Path $ptDir)) { Write-Error "Recovery point not found: $PointId"; exit 1 }

$meta = Get-Content "$ptDir\metadata.json" | ConvertFrom-Json

Write-Host "`n=== ROLLBACK PLAN ===" -ForegroundColor Yellow
Write-Host "  Point   : $($meta.id)"
Write-Host "  Created : $($meta.timestamp)"
Write-Host "  Reason  : $($meta.description)"
Write-Host "  API     : $($meta.apiCommit.Substring(0,8)) ($($meta.apiBranch))"
Write-Host "  DB dump : $($meta.dbDumpSizeKB) KB"
Write-Host ""
Write-Host "  This will:" -ForegroundColor Red
if (-not $DbOnly)   { Write-Host "    - Hard-reset tekeche-api to commit $($meta.apiCommit.Substring(0,8))" }
if (-not $CodeOnly) { Write-Host "    - Drop and restore MongoDB 'tekeche' database" }
Write-Host "    - Reload pm2 tekeche-api"
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Type 'ROLLBACK' to confirm"
    if ($confirm -ne 'ROLLBACK') { Write-Host "Aborted."; exit 0 }
}

Write-Host "`n=== Executing Rollback ===" -ForegroundColor Cyan

# ── Restore code ─────────────────────────────────────────────────────────────
if (-not $DbOnly) {
    Write-Host "  [1/3] Restoring code to $($meta.apiCommit.Substring(0,8))..."
    git -C $API_DIR fetch --quiet 2>&1 | Out-Null
    git -C $API_DIR checkout $meta.apiBranch 2>&1 | Out-Null
    git -C $API_DIR reset --hard $meta.apiCommit 2>&1 | Out-Null
    Write-Host "        Code restored."
}

# ── Restore database ──────────────────────────────────────────────────────────
if (-not $CodeOnly) {
    $dbDumpDir = "$ptDir\db-dump\tekeche"
    if (Test-Path $dbDumpDir) {
        Write-Host "  [2/3] Restoring MongoDB from dump..."
        & $MONGORESTORE --uri $MONGO_URI --db tekeche $dbDumpDir --drop --quiet 2>&1 | Out-Null
        Write-Host "        Database restored."
    } else {
        Write-Host "  [2/3] No DB dump found — skipping database restore."
    }
}

# ── Reload API ────────────────────────────────────────────────────────────────
Write-Host "  [3/3] Reloading tekeche-api..."
pm2 reload tekeche-api --update-env 2>&1 | Out-Null
Start-Sleep -Seconds 4

# ── Quick health check ────────────────────────────────────────────────────────
try {
    $health = Invoke-RestMethod "http://127.0.0.1:5000/health" -TimeoutSec 10
    Write-Host "`n✅ Rollback complete — API healthy (status=$($health.status))" -ForegroundColor Green
} catch {
    Write-Host "`n⚠️  API health check failed after rollback — check pm2 logs" -ForegroundColor Red
}

Write-Host "   Restored from: $($meta.id)"
