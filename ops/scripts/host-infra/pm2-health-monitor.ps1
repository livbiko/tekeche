$env:PM2_HOME = "C:\Users\Administrator\.pm2"
$pm2 = "C:\Users\Administrator\AppData\Roaming\npm\pm2.cmd"
$ecosystemDir = "C:\inetpub\wwwroot\tekeche\tekeche-api"
$logFile = "C:\tekeche-ops\logs\pm2-health-monitor.log"

# tekeche-api's own 3 named apps and the ports they own (from
# tekeche-api\ecosystem.config.js). Remediation below must never touch a
# process outside this list -- other apps (woyo-web, tekeche-bot-fleet, etc.)
# share this box's PM2 daemon and must survive a tekeche-api-only incident.
$targetApps  = @('tekeche-api', 'tekeche-api-staging', 'tekeche-api-local')
$targetPorts = @(5000, 5001, 3000)

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts : $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

# 1. Health check - if healthy, do nothing and exit quietly.
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($resp.StatusCode -eq 200) {
        exit 0
    }
} catch {
    # falls through to remediation
}

Log "Health check failed (non-200 or unreachable) - investigating PM2 state"

# 2. Check whether PM2 itself thinks tekeche-api is healthy.
$pm2Responsive = $true
$tekecheApiOnline = $false
try {
    $jlistRaw = & $pm2 jlist 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $jlistRaw) {
        $pm2Responsive = $false
    } else {
        # pm2 jlist can contain duplicate-key JSON (env vars), so scan as text
        # rather than a strict ConvertFrom-Json parse.
        $text = $jlistRaw -join "`n"
        if ($text -match '"name"\s*:\s*"tekeche-api"[\s\S]{0,400}?"status"\s*:\s*"online"') {
            $tekecheApiOnline = $true
        }
    }
} catch {
    $pm2Responsive = $false
}

if ($pm2Responsive -and $tekecheApiOnline) {
    Log "PM2 reports tekeche-api as online - failure is likely a downstream dependency (Mongo/Redis/etc), not PM2. Not restarting. Manual investigation needed."
    exit 1
}

if ($pm2Responsive) {
    # 3a. PM2 daemon is fine, it just doesn't have tekeche-api's apps up (or
    # doesn't have them registered at all). PM2 itself can be trusted to stop
    # exactly the named apps we ask for -- `pm2 delete <names>` never touches
    # any other app on the daemon, so no raw OS-level process kill is needed
    # in this branch at all.
    Log "PM2 responsive but tekeche-api not online - deleting and restarting only tekeche-api's own apps (no daemon restart, other apps untouched)"
    $deleteOutput = & $pm2 delete $targetApps 2>&1
    Log "pm2 delete output: $($deleteOutput -join ' | ')"
} else {
    # 3b. PM2 daemon itself is unresponsive (the 2026-07-14 WMI/COM crash
    # pattern) - jlist can't tell us anything, so we can't ask PM2 which PIDs
    # are tekeche-api's. Identify them precisely by which process is actually
    # LISTENING on tekeche-api's own ports (5000/5001/3000) instead of a
    # command-line substring match -- a "node.exe ... ProcessContainer.js"
    # command line looks identical for every PM2-managed app on this box, so
    # matching on "pm2" or "tekeche-api" text previously killed the whole
    # daemon (every app) rather than just tekeche-api's 3 processes. Port
    # ownership is the one thing that's actually unique to this app.
    Log "PM2 daemon unresponsive - identifying tekeche-api's own processes by listening port (5000/5001/3000), not by command-line match"

    $targetPids = @{}
    foreach ($p in $targetPorts) {
        try {
            Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop | ForEach-Object {
                $targetPids[$_.OwningProcess] = $p
            }
        } catch {
            # No listener on this port right now - fine, nothing to kill for it.
        }
    }

    foreach ($procId in $targetPids.Keys) {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue).CommandLine
            Log "Killing tekeche-api process PID $procId (port $($targetPids[$procId])): $cmdLine"
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        } catch {}
    }

    # The daemon itself must also go so `pm2 start` below spawns a fresh one
    # instead of trying (and failing) to talk to the wedged original. This is
    # the one deliberate exception to "never touch anything but tekeche-api" --
    # the daemon is genuinely unresponsive to every app at this point, so any
    # other app already can't be managed live either; a fresh daemon plus a
    # `pm2 start` for tekeche-api won't delete other apps' registrations, it
    # just won't know about them until they're next started or resurrected.
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match [regex]::Escape("pm2\lib\Daemon.js")
    } | ForEach-Object {
        Log "Killing unresponsive PM2 daemon PID $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Seconds 3

# 4. Start fresh from the authoritative ecosystem.config.js - deliberately NOT
# `pm2 resurrect`, since a stale dump.pm2 is what caused the 2026-07-14/15 outage.
Push-Location $ecosystemDir
$startOutput = & $pm2 start ecosystem.config.js 2>&1
Pop-Location
Log "pm2 start output: $($startOutput -join ' | ')"

Start-Sleep -Seconds 8

# 5. Re-verify and save a corrected dump on success. Only tekeche-api's own
# apps were touched above, so `pm2 save` here persists exactly the same set
# of other apps (woyo-web, tekeche-bot-fleet, etc.) that were already in the
# snapshot going in -- it no longer silently drops them.
try {
    $resp2 = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($resp2.StatusCode -eq 200) {
        Log "Remediation SUCCESS - health check now returns 200"
        & $pm2 save 2>&1 | Out-Null
        Log "pm2 save completed - dump.pm2 now reflects current state"
    } else {
        Log "Remediation FAILED - health check returned $($resp2.StatusCode) after restart attempt"
    }
} catch {
    Log "Remediation FAILED - health check still unreachable after restart attempt: $_"
}
