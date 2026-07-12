# Alerts if any FSMO role holder becomes unreachable. All 5 FSMO roles sit
# on BikoDC alone (confirmed via Phase 1 HA/DR discovery, 2026-07-12) - AD
# doesn't support automatic FSMO failover by design (Microsoft's own
# guidance: seizing a role while the original holder might still be
# intermittently reachable risks USN rollback / metadata corruption, so
# it's deliberately a manual decision, not something to automate away).
# This script is the actual mitigation: fast alerting + a tested manual
# runbook (FSMO-Seizure-Runbook.md), not automatic seizure.
#
# IMPORTANT: this AD forest is shared with other, unrelated systems
# (ALBANDC, GUIZODC, PASCALEDC, JUMPBOX, BIKORDP1 - see Phase 1 discovery).
# This script only checks reachability, it never modifies AD, so that's not
# a risk here - but keep it in mind before ever writing a script that acts
# on these findings.
#
# Run as a Scheduled Task on BikoDC1 AND BikoDC2 (not BikoDC itself - if
# BikoDC is the thing that's down, a check running on it won't fire).
#
# Deliberately reads SMTP creds from a LOCAL file (C:\ops\fsmo-alert-creds.txt
# on each DC), not BikoDC's tekeche-api\.env: if BikoDC is the machine that's
# down, a UNC path back to it for credentials would be unreachable at
# exactly the moment the alert needs to fire. This duplicates the Brevo
# credentials across BikoDC1/BikoDC2 instead of a single source of truth -
# an accepted, deliberate tradeoff for this specific purpose.

$ErrorActionPreference = "Stop"

function Send-FsmoAlert {
    param([string]$Subject, [string]$Body)

    $credLines = Get-Content "C:\ops\fsmo-alert-creds.txt"
    $login = ($credLines | Where-Object { $_ -match "^BREVO_SMTP_LOGIN=" }) -replace "^BREVO_SMTP_LOGIN=", ""
    $key   = ($credLines | Where-Object { $_ -match "^BREVO_SMTP_KEY=" })   -replace "^BREVO_SMTP_KEY=", ""
    $from  = ($credLines | Where-Object { $_ -match "^BREVO_FROM_EMAIL=" }) -replace "^BREVO_FROM_EMAIL=", ""

    $securePassword = ConvertTo-SecureString $key -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($login, $securePassword)

    Send-MailMessage -SmtpServer "smtp-relay.brevo.com" -Port 587 -UseSsl `
        -Credential $cred -From $from -To "assalehervekouame@gmail.com" `
        -Subject $Subject -Body $Body
}

$fsmoRoles = netdom query fsmo 2>&1 | Where-Object { $_ -match "\S" -and $_ -notmatch "command completed successfully" }
Write-Host "Current FSMO role holders:"
$fsmoRoles | ForEach-Object { Write-Host "  $_" }

# Extract unique DC hostnames from "Role    DC.fqdn" lines
$holders = $fsmoRoles | ForEach-Object {
    if ($_ -match "(\S+\.\S+)\s*$") { $matches[1] }
} | Sort-Object -Unique

$unreachable = @()
foreach ($dc in $holders) {
    $ok = Test-Connection -ComputerName $dc -Count 2 -Quiet -ErrorAction SilentlyContinue
    $ldapOk = $false
    if ($ok) {
        try {
            $null = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$dc")
            $ldapOk = $true
        } catch { $ldapOk = $false }
    }
    Write-Host "$dc -- ping: $ok, LDAP: $ldapOk"
    if (-not $ok -or -not $ldapOk) {
        $unreachable += $dc
    }
}

if ($unreachable.Count -gt 0) {
    $subject = "[ALERT] FSMO role holder unreachable: $($unreachable -join ', ')"
    $body = @"
The following FSMO role holder(s) failed a reachability check (ping and/or LDAP bind) from $env:COMPUTERNAME at $(Get-Date):

$($unreachable -join "`n")

All 5 FSMO roles currently sit on BikoDC alone. If this is BikoDC and it stays unreachable, do NOT seize roles automatically -- follow ops/scripts/FSMO-Seizure-Runbook.md, which requires confirming BikoDC won't come back before seizing (premature seizure risks metadata corruption if the original holder returns).
"@
    Write-Host $subject -ForegroundColor Red
    Send-FsmoAlert -Subject $subject -Body $body
} else {
    Write-Host "All FSMO role holders reachable." -ForegroundColor Green
}

