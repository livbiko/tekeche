<#
.SYNOPSIS
    Classifies a proposed change and shows what is required before proceeding.
    Run this to understand what approvals and steps are needed before any change.

.EXAMPLE
    .\Get-ChangeRisk.ps1 -Change "Increase OTP rate limit"
    .\Get-ChangeRisk.ps1 -Change "Add database index to trips collection"
#>
param(
    [Parameter(Mandatory)][string]$Change
)

$LOW_RISK = @(
    "ui text", "colour", "color", "documentation", "logging", "comment",
    "readme", "typo", "wording", "style", "css", "label", "translation",
    "non-functional", "refactor", "rename variable", "format"
)

$HIGH_RISK = @(
    "database migration", "schema change", "index", "authentication", "auth",
    "jwt", "password", "security", "infrastructure", "production config",
    "push notification", "payment processing", "cinetpay", "firebase",
    "ssl", "certificate", "cors", "env", "environment variable",
    "mongodb", "replica set", "nginx", "iis", "pm2 cluster", "redis"
)

$MEDIUM_RISK = @(
    "new feature", "api", "endpoint", "driver workflow", "passenger workflow",
    "booking", "dispatch", "trip", "rate limit", "wallet", "promo",
    "notification", "email", "otp", "socket", "websocket"
)

$changeLower = $Change.ToLower()
$risk = "MEDIUM"
foreach ($kw in $HIGH_RISK)   { if ($changeLower -match $kw) { $risk = "HIGH";   break } }
foreach ($kw in $LOW_RISK)    { if ($changeLower -match $kw) { $risk = "LOW";    break } }
if ($risk -ne "HIGH") {
    foreach ($kw in $MEDIUM_RISK) { if ($changeLower -match $kw) { $risk = "MEDIUM"; break } }
}

Write-Host "`n┌─────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  CHANGE RISK ASSESSMENT                     │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Change : $Change"

switch ($risk) {
    "LOW" {
        Write-Host "  Risk   : " -NoNewline; Write-Host "LOW" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Required steps:"
        Write-Host "    1. Review the change"
        Write-Host "    2. Confirm approval from user before implementing"
        Write-Host "    3. Commit after change"
        Write-Host ""
        Write-Host "  No recovery point needed for low-risk changes."
        Write-Host "  No maintenance window required."
    }
    "MEDIUM" {
        Write-Host "  Risk   : " -NoNewline; Write-Host "MEDIUM" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Required steps:"
        Write-Host "    1. Create recovery point:"
        Write-Host "       .\New-RecoveryPoint.ps1 -Description `"Before: $Change`""
        Write-Host "    2. Perform impact assessment"
        Write-Host "    3. Define rollback plan"
        Write-Host "    4. Get explicit user approval"
        Write-Host "    5. Implement change"
        Write-Host "    6. Run .\Test-Build.ps1"
        Write-Host "    7. If tests pass, run .\Set-KnownGood.ps1"
        Write-Host ""
        Write-Host "  No maintenance window required."
    }
    "HIGH" {
        Write-Host "  Risk   : " -NoNewline; Write-Host "HIGH ⚠️" -ForegroundColor Red
        Write-Host ""
        Write-Host "  STOP. This change requires a maintenance window." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Required steps:"
        Write-Host "    1. Propose maintenance window (time, duration, risks)"
        Write-Host "    2. Get explicit user approval for the window"
        Write-Host "    3. Create recovery point:"
        Write-Host "       .\New-RecoveryPoint.ps1 -Description `"Before: $Change`""
        Write-Host "    4. Explain full rollback plan before starting"
        Write-Host "    5. Estimate downtime and notify affected parties"
        Write-Host "    6. Implement change during approved window ONLY"
        Write-Host "    7. Run .\Test-Build.ps1 immediately after"
        Write-Host "    8. If tests fail → immediately run .\Invoke-Rollback.ps1 -Latest"
        Write-Host "    9. Log to MAINTENANCE_LOG.md"
    }
}
Write-Host ""
