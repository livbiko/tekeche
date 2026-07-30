<#
.SYNOPSIS
    Drain-first restart wrapper for BikoDC's slice of tekeche-nlb, so a
    planned restart never shows the ~detection-window connection errors
    real unplanned crashes do.

.DESCRIPTION
    2026-07-29: a deliberate BikoDC restart went straight to Restart-Computer
    with no drain first, causing avoidable connection errors during the
    ~restart window (same night as a genuine unplanned crash at 19:43, whose
    outage WAS unavoidable -- this script only closes the avoidable half).

    Two-phase design, because an OS restart ends the PowerShell session that
    triggered it:
      Phase 1 (default invocation): verify the OCI standby is healthy,
      drain 192.168.1.101 on both backend sets, register a one-time
      "At startup" scheduled task that runs Phase 2, then restart (or, with
      -Pm2Only, skip the OS restart and run Phase 2 inline).
      Phase 2 (-PostRestartOnly, run automatically by the scheduled task,
      or inline for -Pm2Only): poll the local API's own /health until it's
      genuinely serving, THEN un-drain. Never un-drains a backend that
      isn't actually healthy yet.

    MEDIUM risk per Get-ChangeRisk.ps1 -- briefly removes BikoDC from
    production rotation (OCI standby carries 100% of traffic for the
    restart's duration, same path already proven in Test-Failover.ps1).

.EXAMPLE
    .\Invoke-SafeRestart.ps1
    Full OS restart of BikoDC, drained first, auto-restored after boot.

.EXAMPLE
    .\Invoke-SafeRestart.ps1 -Pm2Only
    Just `pm2 restart tekeche-api`, drained/restored inline, no reboot.
#>
param(
    [string]$NlbId = "ocid1.networkloadbalancer.oc1.uk-london-1.amaaaaaaoz32urqapxkozt5sb7dky46cq3w5cwvqoludjd6tglccnlureycq",
    [string]$OnpremIp = "192.168.1.101",
    [string]$LocalHealthUrl = "http://localhost:5000/health",
    [int]$ConnectionDrainSeconds = 10,
    [int]$PostBootTimeoutSeconds = 300,
    [switch]$Pm2Only,
    [switch]$PostRestartOnly,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TaskName = "SafeRestart-PostBoot-BikoDC"
$Backends = @(
    @{ Set = "main-backends"; Name = "${OnpremIp}:443" },
    @{ Set = "http-backends"; Name = "${OnpremIp}:80" }
)
$StandbyBackendName = "10.0.2.10:443"

function Set-Drain([bool]$Drain) {
    foreach ($b in $Backends) {
        # NB: "oci nlb backend update" has no --force option (unlike health-checker/network-load-balancer
        # update) -- passing it errors with a CLI usage message that silently vanished into Out-Null,
        # so the drain call never actually ran. Found by testing this exact command by hand.
        oci nlb backend update --network-load-balancer-id $NlbId --backend-set-name $b.Set `
            --backend-name $b.Name --is-drain $Drain.ToString().ToLower() | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "oci nlb backend update failed (exit $LASTEXITCODE) on $($b.Set)/$($b.Name) -- see output above" }
        # oci nlb backend update is async (returns a work request) -- must wait for it to land
        # before verifying, same as Test-Failover.ps1's proven pattern. Checking immediately
        # after issuing the update reads the pre-update state and false-fails every time.
        Start-Sleep -Seconds 8
        $state = (oci nlb backend get --network-load-balancer-id $NlbId --backend-set-name $b.Set `
            --backend-name $b.Name --output json | ConvertFrom-Json).data.'is-drain'
        Write-Host "    $($b.Set)/$($b.Name) is-drain = $state"
        if ($state -ne $Drain) { throw "Drain state didn't apply as expected on $($b.Set)/$($b.Name)" }
    }
}

function Test-StandbyHealthy {
    $health = oci nlb backend-set-health get --network-load-balancer-id $NlbId `
        --backend-set-name main-backends --output json | ConvertFrom-Json
    return -not ($health.data.'critical-state-backend-names' -contains $StandbyBackendName) `
        -and -not ($health.data.'unknown-state-backend-names' -contains $StandbyBackendName)
}

function Wait-ForLocalHealth {
    $deadline = (Get-Date).AddSeconds($PostBootTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-RestMethod -Uri $LocalHealthUrl -TimeoutSec 5
            if ($resp.status -eq "ok" -and $resp.db -eq "connected") { return $true }
        } catch { }
        Start-Sleep -Seconds 5
    }
    return $false
}

function Invoke-Phase2 {
    Write-Host "`n=== Phase 2: waiting for local API to be genuinely healthy ===" -ForegroundColor Cyan
    if (Wait-ForLocalHealth) {
        Write-Host "    Local /health OK (db connected) -- restoring $OnpremIp to rotation" -ForegroundColor Green
        Set-Drain $false
        Write-Host "`n✅  Restart complete, BikoDC restored to tekeche-nlb rotation." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Local /health did NOT come up healthy within $PostBootTimeoutSeconds s -- leaving $OnpremIp DRAINED." -ForegroundColor Red
        Write-Host "    Investigate before manually restoring: oci nlb backend update --network-load-balancer-id $NlbId --backend-set-name main-backends --backend-name ${OnpremIp}:443 --is-drain false" -ForegroundColor Yellow
        Write-Host "    (and the same for http-backends / port 80)" -ForegroundColor Yellow
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
}

if ($PostRestartOnly) {
    Invoke-Phase2
    return
}

Write-Host "`n=== Safe Restart: $OnpremIp ===" -ForegroundColor Cyan
Write-Host "    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

Write-Host "[1/4] Confirming OCI standby ($StandbyBackendName) is healthy before draining on-prem..."
if (-not (Test-StandbyHealthy)) {
    Write-Host "`n❌  OCI standby is NOT currently healthy -- refusing to drain BikoDC (would cause a real outage)." -ForegroundColor Red
    exit 1
}
Write-Host "    Standby healthy, safe to proceed." -ForegroundColor Green

Write-Host "`n[2/4] Draining $OnpremIp from tekeche-nlb (main-backends + http-backends)..."
Set-Drain $true
Write-Host "    Waiting ${ConnectionDrainSeconds}s for in-flight connections to wind down..."
Start-Sleep -Seconds $ConnectionDrainSeconds

if ($Pm2Only) {
    Write-Host "`n[3/4] Restarting tekeche-api via PM2 (no OS reboot)..."
    pm2 restart tekeche-api --update-env | Out-Null
    Write-Host "`n[4/4] Running Phase 2 inline (no reboot means no scheduled task needed)..."
    Invoke-Phase2
} else {
    Write-Host "`n[3/4] Registering one-time post-boot restore task..."
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -PostRestartOnly -NlbId `"$NlbId`" -OnpremIp `"$OnpremIp`" -LocalHealthUrl `"$LocalHealthUrl`" -PostBootTimeoutSeconds $PostBootTimeoutSeconds"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
        -RunLevel Highest -User "SYSTEM" -Force | Out-Null
    Write-Host "    Registered '$TaskName' (runs once at next boot, self-deletes after)." -ForegroundColor Green

    Write-Host "`n[4/4] Restarting BikoDC..."
    if (-not $Force) {
        $confirm = Read-Host "    Type 'yes' to restart now"
        if ($confirm -ne "yes") {
            Write-Host "`n⚠️  Restart cancelled -- $OnpremIp is still DRAINED. Restore manually or re-run to complete the restart." -ForegroundColor Yellow
            exit 1
        }
    }
    Restart-Computer -Force
}
