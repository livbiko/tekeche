<#
.SYNOPSIS
    Live drain/restore drill for the BikoDC-primary / OCI-standby failover
    path (api.tekeche.com), via the real NLB rather than simulated.

.DESCRIPTION
    Same drain -> verify -> restore -> verify pattern used in every prior
    manual drill (see MAINTENANCE_LOG.md, e.g. 2026-07-17/18/19/20 entries).
    Resolves directly against the NLB's public IP with -Resolve, NOT local
    DNS -- BikoDC hosts its own split-horizon zone for tekeche.com/api, so
    on-prem-originated requests to api.tekeche.com never reach the NLB at
    all and always show the on-prem ARR header, drained or not. Running
    this from an on-prem box without the IP pin gives a false "still
    on-prem" result even when the drain genuinely applied -- caught the
    hard way on 2026-07-20, don't repeat that mistake.

    MEDIUM risk per Get-ChangeRisk.ps1 -- briefly routes real production
    traffic through the OCI standby. Follow the standard protocol: recovery
    point first, explicit approval, Test-Build.ps1 after.

.EXAMPLE
    .\Test-Failover.ps1
#>
param(
    [string]$NlbId = "ocid1.networkloadbalancer.oc1.uk-london-1.amaaaaaaoz32urqapxkozt5sb7dky46cq3w5cwvqoludjd6tglccnlureycq",
    [string]$BackendSetName = "main-backends",
    [string]$OnpremBackendName = "192.168.1.101:443",
    [string]$Hostname = "api.tekeche.com",
    [string]$HealthPath = "/health"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-NlbPublicIp {
    $json = oci nlb network-load-balancer get --network-load-balancer-id $NlbId --output json | ConvertFrom-Json
    return $json.data.'ip-addresses'[0].'ip-address'
}

function Test-Endpoint($nlbIp, $label, $count = 5) {
    $onprem = 0
    $standby = 0
    for ($i = 1; $i -le $count; $i++) {
        $resp = curl.exe -s -i --resolve "${Hostname}:443:${nlbIp}" "https://$Hostname$HealthPath" 2>$null
        $code = ($resp | Select-String "^HTTP/") -replace '.*\s(\d{3})\s.*', '$1'
        $isOnprem = ($resp | Select-String -Quiet "X-Powered-By:\s*ARR")
        if ($isOnprem) { $onprem++ } else { $standby++ }
        Write-Host "    [$i] HTTP $code  $(if ($isOnprem) { 'on-prem (ARR)' } else { 'standby (no ARR)' })"
    }
    Write-Host "  -> ${label}: $onprem on-prem / $standby standby of $count" -ForegroundColor Cyan
    return @{ Onprem = $onprem; Standby = $standby }
}

Write-Host "`n=== BikoDC <-> OCI Standby Failover Drill ===" -ForegroundColor Cyan
Write-Host "    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

$nlbIp = Get-NlbPublicIp
Write-Host "NLB public IP: $nlbIp (resolving directly, bypassing local DNS)`n"

Write-Host "[1/5] Baseline check..."
$baseline = Test-Endpoint $nlbIp "Baseline"
if ($baseline.Onprem -ne 5) {
    Write-Host "`n⚠️  Baseline isn't clean on-prem (expected 5/5) -- stopping before draining anything." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[2/5] Draining on-prem backend ($OnpremBackendName)..."
oci nlb backend update --network-load-balancer-id $NlbId --backend-set-name $BackendSetName --backend-name $OnpremBackendName --is-drain true | Out-Null
Start-Sleep -Seconds 8
$drainState = (oci nlb backend get --network-load-balancer-id $NlbId --backend-set-name $BackendSetName --backend-name $OnpremBackendName --output json | ConvertFrom-Json).data.'is-drain'
Write-Host "    Confirmed is-drain = $drainState"

Write-Host "`n[3/5] During-drain check (should be all standby)..."
$during = Test-Endpoint $nlbIp "During drain"

Write-Host "`n[4/5] Restoring on-prem backend..."
oci nlb backend update --network-load-balancer-id $NlbId --backend-set-name $BackendSetName --backend-name $OnpremBackendName --is-drain false | Out-Null
Start-Sleep -Seconds 8
$drainState = (oci nlb backend get --network-load-balancer-id $NlbId --backend-set-name $BackendSetName --backend-name $OnpremBackendName --output json | ConvertFrom-Json).data.'is-drain'
Write-Host "    Confirmed is-drain = $drainState"

Write-Host "`n[5/5] Post-restore check..."
$restored = Test-Endpoint $nlbIp "Post-restore"

Write-Host "`n═══════════════════════════════════" -ForegroundColor Cyan
$ok = ($baseline.Onprem -eq 5) -and ($during.Standby -eq 5) -and ($restored.Onprem -eq 5)
if ($ok) {
    Write-Host "  ✅  Failover drill PASSED — clean drain, standby served real traffic, clean restore" -ForegroundColor Green
} else {
    Write-Host "  ❌  Failover drill result unexpected — review output above before trusting this path" -ForegroundColor Red
}
Write-Host "═══════════════════════════════════`n"

Write-Host "Remember: run Test-Build.ps1 next, and log the result to MAINTENANCE_LOG.md per protocol." -ForegroundColor Yellow

return $ok
