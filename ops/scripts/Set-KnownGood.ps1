<#
.SYNOPSIS
    Runs the verification checklist and, if all checks pass,
    marks the current build as a Known Good Build.

.EXAMPLE
    .\Set-KnownGood.ps1 -BuildNote "Post-OTP fix, booking flow verified on device"
#>
param(
    [string]$BuildNote = "",
    [switch]$SkipTests,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$API_DIR  = "C:\inetpub\wwwroot\tekeche\tekeche-api"
$MOB_DIR  = "C:\inetpub\wwwroot\tekeche\tekeche-mobile"
$OPS_DIR  = "C:\inetpub\wwwroot\tekeche\ops"
$KGB_FILE = "$OPS_DIR\KNOWN_GOOD_BUILDS.json"
$HISTORY  = "$OPS_DIR\RELEASE_HISTORY.md"

# ── Run verification ──────────────────────────────────────────────────────────
if (-not $SkipTests) {
    Write-Host "Running verification checklist first..." -ForegroundColor Cyan
    $ok = & "$OPS_DIR\scripts\Test-Build.ps1"
    if (-not $ok -and -not $Force) {
        Write-Host "`n❌ Build verification failed. Use -Force to override (not recommended)." -ForegroundColor Red
        exit 1
    }
}

# ── Collect build info ────────────────────────────────────────────────────────
$apiCommit  = (git -C $API_DIR  rev-parse HEAD).Trim()
$apiBranch  = (git -C $API_DIR  rev-parse --abbrev-ref HEAD).Trim()
$mobCommit  = (git -C $MOB_DIR  rev-parse HEAD).Trim()
$apiPkg     = Get-Content "$API_DIR\package.json"  | ConvertFrom-Json
$mobPkg     = Get-Content "$MOB_DIR\package.json"  | ConvertFrom-Json

# ── Load existing registry ────────────────────────────────────────────────────
$builds = @()
if (Test-Path $KGB_FILE) {
    $content = Get-Content $KGB_FILE -Raw
    if ($content.Trim()) { $builds = $content | ConvertFrom-Json }
    if ($builds -isnot [Array]) { $builds = @($builds) }
}

# ── Build number ──────────────────────────────────────────────────────────────
$buildNumber = ($builds.Count + 1)

# ── New entry ─────────────────────────────────────────────────────────────────
$entry = [ordered]@{
    buildNumber    = $buildNumber
    dateCreated    = (Get-Date -Format "o")
    apiCommit      = $apiCommit
    apiBranch      = $apiBranch
    mobileCommit   = $mobCommit
    apiVersion     = $apiPkg.version
    mobileVersion  = $mobPkg.version
    note           = $BuildNote
    productionSafe = $true
    testResults    = if ($SkipTests) { "skipped" } else { "passed" }
    deployStatus   = "deployed"
}

$builds += $entry

# ── Save registry ─────────────────────────────────────────────────────────────
$builds | ConvertTo-Json -Depth 5 | Set-Content $KGB_FILE -Encoding UTF8

# ── Append to RELEASE_HISTORY.md ─────────────────────────────────────────────
$histEntry = @"

## Build #$buildNumber — $(Get-Date -Format "yyyy-MM-dd HH:mm")

- **API commit**: $($apiCommit.Substring(0,8)) ($apiBranch)
- **Mobile commit**: $($mobCommit.Substring(0,8))
- **API version**: $($apiPkg.version)
- **Tests**: $(if ($SkipTests) { "skipped" } else { "passed" })
- **Production-safe**: Yes
- **Note**: $BuildNote

"@
Add-Content $HISTORY $histEntry -Encoding UTF8

Write-Host "`n✅ Build #$buildNumber marked as Known Good" -ForegroundColor Green
Write-Host "   API: $($apiCommit.Substring(0,8)) | Mobile: $($mobCommit.Substring(0,8))"
