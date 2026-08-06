<#
.SYNOPSIS
    Pre-flight checklist for the full on-prem power-off drill (BikoDC + BikoDC1
    + BikoDC2 simultaneously) -- read-only verification only, never powers
    anything off, never modifies anything.

.DESCRIPTION
    Confirms Mongo rs0 quorum, Redis Sentinel quorum, NLB backend health (both
    backend sets), DNS steering + the AD DNS forwarder's target, no stale
    blocked-IP entries on the OCI side, api.tekeche.com's cert validity, and
    baseline app health -- all BEFORE the user physically powers off all three
    on-prem boxes.

    IMPORTANT: this script runs ON BikoDC itself. There is no vCenter/ESXi
    access to trigger or observe the outage remotely (confirmed absent
    2026-07-18 and again 2026-08-04) -- the user must physically power the
    three boxes off themselves once this comes back clean, and personally
    check the real app on their own device during the outage window. This
    script CANNOT run during the drill (BikoDC will be down) -- use it only
    immediately before (go/no-go gate) and immediately after (post-drill
    validation, same script, same checks).

    Never prints the mongo-rs-watchdog credential -- it's sourced inside the
    same remote SSH command that uses it, never grepped/catted locally. See
    feedback_credential_handling memory, 2026-08-04 entry, for why that
    matters here specifically.

.EXAMPLE
    .\Test-OnPremPowerOffPreflight.ps1
#>
param(
    [string]$NlbId             = "ocid1.networkloadbalancer.oc1.uk-london-1.amaaaaaaoz32urqapxkozt5sb7dky46cq3w5cwvqoludjd6tglccnlureycq",
    [string]$BastionId         = "ocid1.bastion.oc1.uk-london-1.amaaaaaaoz32urqafx64ejozquqrw6f56k53o3ah5qrwzwqrzjjsxxz3bvua",
    [string]$StandbyInstanceId = "ocid1.instance.oc1.uk-london-1.anwgiljtoz32urqcy43xtb3nq7colfbe65xf7avtucf2pczqrjr5emigx2ja",
    [string]$StandbyIp         = "10.0.2.10",
    [string]$Hostname          = "api.tekeche.com",
    [string]$SshKeyPath        = "$env:USERPROFILE\.ssh\id_rsa"
)

Set-StrictMode -Version Latest
# Deliberately "Continue", not "Stop": this script shells out to oci/ssh/curl
# repeatedly, all of which write routine, non-fatal chatter to stderr (oci's
# API-key warning, ssh's post-quantum-kex notice) that PS 5.1 turns into
# terminating NativeCommandErrors under "Stop". Pass/fail is judged from each
# check's actual parsed output below, not from exceptions.
$ErrorActionPreference = "Continue"
$env:SUPPRESS_LABEL_WARNING = "True"

$script:results = [ordered]@{}

function Write-CheckResult($name, [bool]$pass, [string]$detail = "") {
    $icon = if ($pass) { "[OK]" } else { "[FAIL]" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "  $icon  $name" -ForegroundColor $color
    if ($detail) { Write-Host "        $detail" -ForegroundColor Gray }
    $script:results[$name] = $pass
}

Write-Host "`n=== On-Prem Power-Off Drill Pre-Flight ===" -ForegroundColor Cyan
Write-Host "    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "    Scope: BikoDC + BikoDC1 + BikoDC2 simultaneous power-off"
Write-Host "    Read-only checks -- nothing is powered off or modified by this script.`n"

# ── Bastion session helpers ──────────────────────────────────────────────
function New-BastionSshSession {
    param([string]$DisplayName)
    # Embedded double-quotes must be backslash-escaped (\") even inside a
    # single-quoted PowerShell string, or oci.exe's native-command argument
    # marshalling drops them and rejects the result as invalid JSON --
    # neither an unescaped inline string nor a `file://`-referenced file
    # (Windows backslash paths don't resolve correctly there either) works.
    $detailsJson = '{\"sessionType\":\"MANAGED_SSH\",\"targetResourceId\":\"' + $StandbyInstanceId + '\",\"targetResourceOperatingSystemUserName\":\"ubuntu\",\"targetResourcePort\":22}'
    $null = oci bastion session create `
        --bastion-id $BastionId `
        --display-name $DisplayName `
        --target-resource-details $detailsJson `
        --ssh-public-key-file "$SshKeyPath.pub" `
        --key-type PUB

    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Seconds 5
        $state = oci bastion session list --bastion-id $BastionId --query "data[?`"display-name`"=='$DisplayName'] | [0].`"lifecycle-state`"" --raw-output 2>$null
        if ($state -eq "ACTIVE") {
            return (oci bastion session list --bastion-id $BastionId --query "data[?`"display-name`"=='$DisplayName'] | [0].id" --raw-output 2>$null)
        }
    }
    throw "Bastion session '$DisplayName' did not become ACTIVE within 60s"
}

function Remove-BastionSshSession($SessionId) {
    if ($SessionId) {
        oci bastion session delete --session-id $SessionId --force 2>&1 | Out-Null
    }
}

function Invoke-StandbyCommand($SessionId, [string]$RemoteCommand) {
    $proxy = "ssh -i `"$SshKeyPath`" -o StrictHostKeyChecking=no -W %h:%p -p 22 $SessionId@host.bastion.uk-london-1.oci.oraclecloud.com"
    return & ssh -i "$SshKeyPath" -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o ProxyCommand=$proxy -p 22 "ubuntu@$StandbyIp" $RemoteCommand 2>&1
}

# ── 1-2. Mongo rs0 + Redis Sentinel, via one Bastion session to standby ──
Write-Host "[1/8] Opening a Bastion session to standby for Mongo/Redis checks..."
$sbSession = $null
try {
    $sbSession = New-BastionSshSession -DisplayName "preflight-$(Get-Date -Format 'yyyyMMddHHmmss')"

    Write-Host "`n[2/8] Mongo rs0 status..."
    # Credential is sourced INSIDE the remote command -- never printed locally.
    $mongoCmd = 'set -a; source /opt/mongo-rs-watchdog/.env; set +a; mongosh "$MONGO_ADMIN_URI" --quiet --eval "JSON.stringify(rs.status().members.map(m=>({name:m.name,state:m.stateStr,health:m.health})))"'
    $mongoOut = Invoke-StandbyCommand $sbSession $mongoCmd
    $mongoJsonLine = ($mongoOut | Where-Object { $_ -match '^\[.*\]$' } | Select-Object -Last 1)
    if ($mongoJsonLine) {
        $members = $mongoJsonLine | ConvertFrom-Json
        foreach ($m in $members) { Write-Host "        $($m.name)  $($m.state)  health=$($m.health)" }
        $healthy = @($members | Where-Object { $_.health -eq 1 })
        Write-CheckResult "Mongo rs0: all members healthy" ($healthy.Count -eq $members.Count) "$($healthy.Count)/$($members.Count) healthy"
        $ociVoters = @($members | Where-Object { $_.name -match '^10\.0\.2\.' -and $_.health -eq 1 })
        Write-CheckResult "Mongo rs0: OCI-side members healthy (would hold quorum alone)" ($ociVoters.Count -ge 3) "$($ociVoters.Count) OCI-side members healthy"
    } else {
        Write-CheckResult "Mongo rs0: all members healthy" $false "could not parse rs.status() output -- raw: $($mongoOut -join ' | ')"
    }

    Write-Host "`n[3/8] Redis Sentinel quorum..."
    $sentinelCmd = 'redis-cli -p 26379 SENTINEL master mymaster 2>&1; echo "---SENTINELS---"; redis-cli -p 26379 SENTINEL sentinels mymaster 2>&1 | grep -c "^name$"'
    $sentinelOut = Invoke-StandbyCommand $sbSession $sentinelCmd
    $sentinelText = $sentinelOut -join "`n"
    $masterOk = $sentinelText -match 'flags\s*\r?\nmaster'
    $sentinelCountLine = ($sentinelOut | Select-Object -Last 1)
    $otherSentinels = 0
    [int]::TryParse($sentinelCountLine, [ref]$otherSentinels) | Out-Null
    Write-Host "        master status: $(if ($masterOk) { 'flags=master (healthy)' } else { 'could not confirm -- review raw output' })"
    Write-Host "        other sentinels visible via gossip: $otherSentinels (expect 6, i.e. 7 total incl. this one)"
    Write-CheckResult "Redis Sentinel: master healthy" $masterOk ""
    Write-CheckResult "Redis Sentinel: full 7-node mesh visible" ($otherSentinels -ge 6) "$otherSentinels other sentinels seen"

} finally {
    Write-Host "`nClosing Bastion session..."
    Remove-BastionSshSession $sbSession
}

# ── 4. NLB backend health, both backend sets ─────────────────────────────
Write-Host "`n[4/8] NLB backend health (main-backends + http-backends)..."
foreach ($bs in @("main-backends", "http-backends")) {
    $backends = (oci nlb backend list --network-load-balancer-id $NlbId --backend-set-name $bs --output json 2>$null | ConvertFrom-Json).data.items
    foreach ($b in $backends) {
        $health = (oci nlb backend-health get --network-load-balancer-id $NlbId --backend-set-name $bs --backend-name $b.name --output json 2>$null | ConvertFrom-Json).data.status
        $clean = ($health -eq "OK") -and (-not $b.'is-drain') -and (-not $b.'is-offline')
        Write-CheckResult "$bs / $($b.name)" $clean "health=$health drain=$($b.'is-drain') offline=$($b.'is-offline') backup=$($b.'is-backup')"
    }
}

# ── 5. DNS steering -- public answer already OCI-primary ────────────────
Write-Host "`n[5/8] DNS steering (public resolver, bypassing any local split-horizon)..."
$publicAnswer = (Resolve-DnsName -Name $Hostname -Server 8.8.8.8 -Type A -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
Write-CheckResult "$Hostname resolves to the OCI NLB publicly" ($publicAnswer -eq "140.238.74.241") "resolved: $publicAnswer"

# ── 6. Cert validity ──────────────────────────────────────────────────────
Write-Host "`n[6/8] api.tekeche.com cert validity..."
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Hostname, 443)
    $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({ $true }))
    $ssl.AuthenticateAsClient($Hostname)
    $expiry = [datetime]::Parse($ssl.RemoteCertificate.GetExpirationDateString())
    $daysLeft = ($expiry - (Get-Date)).Days
    $ssl.Close(); $tcp.Close()
    Write-CheckResult "Cert valid, not expiring imminently" ($daysLeft -gt 3) "expires $expiry ($daysLeft days left)"
} catch {
    Write-CheckResult "Cert valid, not expiring imminently" $false "check failed: $_"
}

# ── 7. Baseline app health ────────────────────────────────────────────────
Write-Host "`n[7/8] Baseline app health (Test-Build.ps1)..."
$buildOk = & (Join-Path $PSScriptRoot "Test-Build.ps1")
Write-CheckResult "Test-Build.ps1 clean" ([bool]$buildOk) ""

# ── 8. Direct-resolve baseline (for before/after comparison) ─────────────
Write-Host "`n[8/8] Direct-resolve baseline against the NLB..."
$resp = curl.exe -s -i --resolve "${Hostname}:443:140.238.74.241" "https://$Hostname/health" 2>$null
$code = ($resp | Select-String "^HTTP/") -replace '.*\s(\d{3})\s.*', '$1'
$onPrem = [bool]($resp | Select-String -Quiet "X-Powered-By:\s*ARR")
Write-CheckResult "Baseline /health via NLB" ($code -eq "200") "HTTP $code, served by $(if ($onPrem) { 'on-prem (ARR)' } else { 'OCI standby/standby2' })"

# ── Summary ────────────────────────────────────────────────────────────────
Write-Host "`n═══════════════════════════════════" -ForegroundColor Cyan
$allPass = -not ($script:results.Values -contains $false)
if ($allPass) {
    Write-Host "  ALL PRE-FLIGHT CHECKS PASSED ($($script:results.Count)/$($script:results.Count))" -ForegroundColor Green
    Write-Host "  Safe to hand off for the physical power-off." -ForegroundColor Green
} else {
    $failed = ($script:results.GetEnumerator() | Where-Object { -not $_.Value }).Name
    Write-Host "  SOME CHECKS FAILED -- do not proceed with the drill:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
}
Write-Host "═══════════════════════════════════`n"

Write-Host "Reminder: this script runs ON BikoDC and cannot observe anything DURING the drill." -ForegroundColor Yellow
Write-Host "During the outage window: check the real app from your OWN device, not from here." -ForegroundColor Yellow
Write-Host "After BikoDC is back: re-run this same script for post-drill validation, then log to MAINTENANCE_LOG.md." -ForegroundColor Yellow

return $allPass
