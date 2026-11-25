<#
.SYNOPSIS
    Uptime check OUTSIDE the on-prem RKE2 cluster (CR-2026-11-25-01). Runs on BikoDC as the scheduled task
    "NDP-Uptime-Outside" every 2 minutes.

.DESCRIPTION
    Checks every public hostname through the public IP (curl --resolve, full TLS check). Mails the owner via the
    Brevo API when the sites fail 2 runs in a row, and once when they recover -- the same rule as the in-cluster
    CronJob nouvellesdupays-uptime, which could not alert when the cluster itself failed (CR-2026-11-20-02).

    The Brevo key lives in $KeyFile, DPAPI-encrypted with LocalMachine scope (readable on BikoDC only). Never put
    it in git or print it. Create it with:  .\Watch-PublicUptime.ps1 -StoreKeyFromStdin  (key on stdin).

.EXAMPLE
    .\Watch-PublicUptime.ps1                       # one normal run
    .\Watch-PublicUptime.ps1 -SendTestMail         # proves mail delivery
    .\Watch-PublicUptime.ps1 -StateFile C:\ops\uptime-outside\state-test.json -Targets 'fake|https://nouvellesdupays.com:9/' -Tag '[TEST] '
#>
param(
    [string]$PublicIp = '81.130.238.41',
    # "name|url" -- name is only for the mail.
    [string[]]$Targets = @(
        'nouvellesdupays.com|https://nouvellesdupays.com/',
        'nouvellesdupays.com API|https://nouvellesdupays.com/api/countries',
        'tekeche.com|https://tekeche.com/',
        'api.tekeche.com|https://api.tekeche.com/health',
        'livbiko.com|https://livbiko.com/',
        '225woyo.com|https://225woyo.com/',
        'kendebabi.com|https://kendebabi.com/'
    ),
    [string]$Dir = 'C:\ops\uptime-outside',
    [string]$StateFile = 'C:\ops\uptime-outside\state.json',
    [string]$KeyFile = 'C:\ops\uptime-outside\brevo.key',
    [string]$To = 'assalehervekouame@gmail.com',
    [string]$From = 'noreply@nouvellesdupays.com',
    [int]$FailThreshold = 2,
    [string]$Tag = '',
    [switch]$SendTestMail,
    [switch]$StoreKeyFromStdin
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security
$curl = Join-Path $env:SystemRoot 'System32\curl.exe'
$log = Join-Path $Dir 'uptime.log'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

function Write-Log($msg) {
    $line = '{0} {1}' -f (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'), $msg
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 5MB) { Move-Item $log "$log.1" -Force }
    Add-Content -Path $log -Value $line -Encoding UTF8
}

if ($StoreKeyFromStdin) {
    $key = ([Console]::In.ReadToEnd()).Trim()
    if ($key.Length -lt 20) { throw 'No key on stdin.' }
    $enc = [Security.Cryptography.ProtectedData]::Protect([Text.Encoding]::UTF8.GetBytes($key), $null, 'LocalMachine')
    [IO.File]::WriteAllText($KeyFile, [Convert]::ToBase64String($enc))
    # SYSTEM + Administrators only.
    icacls $KeyFile /inheritance:r /grant:r 'SYSTEM:(R)' 'Administrators:(F)' | Out-Null
    Write-Output "Key stored ($KeyFile)."
    return
}

function Get-BrevoKey {
    $enc = [Convert]::FromBase64String([IO.File]::ReadAllText($KeyFile).Trim())
    [Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect($enc, $null, 'LocalMachine'))
}

function Send-Mail($subject, $text) {
    $body = @{
        sender      = @{ email = $From; name = 'NouvellesDuPays uptime (BikoDC)' }
        to          = @(@{ email = $To })
        subject     = $subject
        textContent = $text
    } | ConvertTo-Json -Depth 4
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-RestMethod -Method Post -Uri 'https://api.brevo.com/v3/smtp/email' -TimeoutSec 30 `
        -Headers @{ 'api-key' = (Get-BrevoKey); accept = 'application/json' } `
        -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
}

if ($SendTestMail) {
    Send-Mail "$Tag[TEST] uptime-outside: mail delivery works" "Test from the BikoDC uptime check (CR-2026-11-25-01). No action needed."
    Write-Log 'test mail sent'
    Write-Output 'Test mail sent.'
    return
}

# One check per target: 2xx/3xx = up; anything else (incl. TLS errors, timeouts) = down.
$failed = @()
foreach ($t in $Targets) {
    $name, $url = $t -split '\|', 2
    $u = [Uri]$url
    $port = if ($u.IsDefaultPort) { 443 } else { $u.Port }
    $out = & $curl -s -o NUL -w '%{http_code}' --max-time 15 --resolve "$($u.Host):$($port):$PublicIp" $url 2>$null
    $rc = $LASTEXITCODE
    $code = [int]("0$out" -replace '\D', '')
    if ($rc -ne 0 -or $code -lt 200 -or $code -ge 400) { $failed += "$name ($url): HTTP $code, curl exit $rc" }
}

$state = @{ state = 'up'; count = 0; since = '' }
if (Test-Path $StateFile) {
    $s = Get-Content $StateFile -Raw | ConvertFrom-Json
    $state = @{ state = $s.state; count = [int]$s.count; since = $s.since }
}
$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' UTC'

if ($failed.Count) {
    $state.count += 1
    Write-Log ("FAIL run {0}: {1}" -f $state.count, ($failed -join '; '))
    if ($state.state -eq 'up' -and $state.count -ge $FailThreshold) {
        $state.state = 'down'; $state.since = $now
        Send-Mail "$($Tag)DOWN: $($failed.Count) of $($Targets.Count) public sites failing" (
            "Seen from BikoDC through the public IP $PublicIp, $FailThreshold checks in a row ($now):`n`n" +
            ($failed -join "`n") + "`n`nFirst places to look: on-prem RKE2 .51 (rke2-server / etcd), dr-haproxy .50 (port 80), IIS on BikoDC, the BT Hub.")
        Write-Log 'DOWN mail sent'
    }
} else {
    if ($state.state -eq 'down') {
        Send-Mail "$($Tag)UP: all public sites answer again" "All $($Targets.Count) checks pass again ($now). Down since $($state.since)."
        Write-Log 'UP mail sent'
    }
    $state = @{ state = 'up'; count = 0; since = '' }
}
$state.last_run = $now
$state | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
