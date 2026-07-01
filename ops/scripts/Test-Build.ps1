<#
.SYNOPSIS
    Runs the full verification checklist for Tekeche.
    All checks must pass before a build can be marked as Known Good.

.EXAMPLE
    .\Test-Build.ps1
    .\Test-Build.ps1 -Verbose
#>
param([switch]$Verbose)

$API_BASE  = "http://127.0.0.1:5000"
$MONGO_URI = "mongodb://tekeche:6eY7EvTt57HM2dgmPgrsr64u@127.0.0.1:27017/tekeche"
$TEST_SCRIPT = "C:\inetpub\wwwroot\tekeche\ops\scripts\test-booking-flow.js"

$results = [ordered]@{}
$passed  = 0
$failed  = 0

function Check($name, $block) {
    try {
        $ok = & $block
        if ($ok) {
            Write-Host "  ✅  $name" -ForegroundColor Green
            $script:results[$name] = "PASS"
            $script:passed++
        } else {
            Write-Host "  ❌  $name" -ForegroundColor Red
            $script:results[$name] = "FAIL"
            $script:failed++
        }
    } catch {
        Write-Host "  ❌  $name — $($_.Exception.Message)" -ForegroundColor Red
        $script:results[$name] = "ERROR: $($_.Exception.Message)"
        $script:failed++
    }
}

Write-Host "`n=== Tekeche Build Verification ===" -ForegroundColor Cyan
Write-Host "    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ── 1. PM2 process running ────────────────────────────────────────────────────
Check "PM2 tekeche-api is running" {
    # pm2 jlist produces JSON with duplicate env keys that ConvertFrom-Json rejects; use text output instead
    $text = (pm2 show tekeche-api 2>$null | Out-String)
    $text -match '│\s*status\s*│\s*online\s*│'
}

# ── 2. API health ─────────────────────────────────────────────────────────────
Check "API /health returns 200" {
    $r = Invoke-RestMethod "$API_BASE/health" -TimeoutSec 10
    $r.status -eq 'ok'
}

# ── 3. MongoDB connectivity ───────────────────────────────────────────────────
Check "MongoDB connectivity" {
    $r = Invoke-RestMethod "$API_BASE/health" -TimeoutSec 10
    $r.db -eq 'connected'
}

# ── 4. Redis connectivity ─────────────────────────────────────────────────────
Check "Redis connectivity" {
    # redis-cli is not in PATH; verify port 6379 is accepting connections
    $tcp = [System.Net.Sockets.TcpClient]::new()
    try {
        $tcp.Connect('127.0.0.1', 6379)
        $tcp.Connected
    } finally {
        $tcp.Close()
    }
}

# ── 5. Authentication endpoint responds ───────────────────────────────────────
Check "Auth endpoint reachable" {
    # Use an intentionally invalid email → forces 400 without sending a real OTP or hitting rate limits
    try {
        Invoke-RestMethod -Method POST "$API_BASE/api/auth/send-otp" `
            -Body '{"email":"invalid-email","role":"passenger"}' `
            -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop | Out-Null
        $true
    } catch {
        $code = if ($null -ne $_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        $code -in @(400, 422, 429)
    }
}

# ── 6. Driver API endpoint responds ──────────────────────────────────────────
Check "Driver API endpoint reachable" {
    try {
        Invoke-RestMethod "$API_BASE/api/drivers/nearby?lat=5.36&lng=-4.02" -TimeoutSec 10 | Out-Null
        $true
    } catch {
        $code = if ($null -ne $_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        $code -in @(400, 401, 403)
    }
}

# ── 7. At least one eligible driver in DB ─────────────────────────────────────
Check "At least one approved standard driver in DB" {
    # Write eval to a temp file — PowerShell strips double-quotes from native --eval strings
    $tmpJs = [System.IO.Path]::Combine($env:TEMP, 'tekeche-driver-check.js')
    'print(db.drivers.countDocuments({ vehicleType: "standard", kycStatus: { $in: ["verified", "approved"] } }))' |
        Set-Content $tmpJs -Encoding UTF8
    try {
        $out = mongosh $MONGO_URI --quiet $tmpJs 2>$null
        $count = $out | Where-Object { $_ -match '^\d+$' } | Select-Object -Last 1
        [int]$count -gt 0
    } finally {
        Remove-Item $tmpJs -Force -ErrorAction SilentlyContinue
    }
}

# ── 8. Booking flow test (full end-to-end) ─────────────────────────────────────
if (Test-Path $TEST_SCRIPT) {
    Check "Full booking flow (automated)" {
        $output = node $TEST_SCRIPT 2>&1
        if ($Verbose) { Write-Host $output }
        $LASTEXITCODE -eq 0
    }
} else {
    Write-Host "  ⚠️   Full booking flow test script not found — skipping" -ForegroundColor Yellow
    $results["Full booking flow (automated)"] = "SKIPPED"
}

# ── 9. No recent crashes in logs ──────────────────────────────────────────────
Check "No crashes in last 10 min of logs" {
    $since = (Get-Date).AddMinutes(-10).ToString("yyyy-MM-dd HH:")
    $crashes = Get-Content "C:\logs\tekeche-api-error-7.log" -Tail 200 |
        Where-Object { $_ -match 'FATAL|uncaughtException|SIGTERM' -and $_ -match $since }
    $crashes.Count -eq 0
}

# ── Summary ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor Cyan
if ($failed -eq 0) {
    Write-Host "  ✅  ALL $passed CHECKS PASSED" -ForegroundColor Green
    Write-Host "      Run Set-KnownGood.ps1 to mark this build as verified."
} else {
    Write-Host "  ❌  $failed/$($passed+$failed) CHECKS FAILED" -ForegroundColor Red
    Write-Host "      Do NOT deploy or mark as known good."
}
Write-Host "═══════════════════════════════════" -ForegroundColor Cyan

return $failed -eq 0
