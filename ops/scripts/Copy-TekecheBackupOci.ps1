<#
.SYNOPSIS
    Copies each Tekeche MongoDB backup folder off-site to OCI Object Storage (CR-2026-11-16-09).

.DESCRIPTION
    Run hourly by the task Tekeche-Backup-Offsite (:25), after Tekeche-MongoDB-Backup (:10) has written
    C:\backups\tekeche\<timestamp>. Every folder not yet uploaded goes to <bucket>/tekeche/<timestamp>/<file>
    (bulk-upload --no-overwrite), then the bucket listing for that prefix must match the folder's files and sizes.
    Uploaded folders are remembered in offsite-done.txt; one line per run goes to offsite.log.
    Uses the existing OCI CLI config; no keys or passwords in this script. Exits 1 on any failure.

.EXAMPLE
    .\Copy-TekecheBackupOci.ps1
#>
param(
    [string]$Src    = "C:\backups\tekeche",
    [string]$Bucket = "tekeche-mongo-backups",
    [string]$Config = "C:\Users\Administrator\.oci\config"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"   # oci.exe writes warnings to stderr; failures are judged by exit code
$env:SUPPRESS_LABEL_WARNING = "True"
$OCI  = "C:\tools\oci-cli\bin\oci.exe"
$LOG  = "$Src\offsite.log"
# Not $DONE: PowerShell variable names ignore case, so $done (the list below) would overwrite it.
$DONE_FILE = "$Src\offsite-done.txt"

function Log([string]$msg) { Add-Content $LOG "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')) $msg" }

$uploaded = @(if (Test-Path $DONE_FILE) { Get-Content $DONE_FILE })
$todo = @(Get-ChildItem $Src -Directory | Where-Object { $_.Name -notin $uploaded } | Sort-Object Name)
$failed = 0
foreach ($dir in $todo) {
    $files = @(Get-ChildItem $dir.FullName -File)
    if ($files.Count -eq 0) { continue }   # backup still being written, or empty: next run
    $prefix = "tekeche/$($dir.Name)/"
    $out = & $OCI --config-file $Config os object bulk-upload --bucket-name $Bucket --src-dir $dir.FullName `
        --object-prefix $prefix --no-overwrite 2>&1
    if ($LASTEXITCODE -ne 0) { $failed++; Log "FAIL upload $($dir.Name): $(("$out" -split "`n" | Select-String 'code|message' | Select-Object -First 2) -join ' ')"; continue }
    $listed = & $OCI --config-file $Config os object list --bucket-name $Bucket --prefix $prefix --all --fields name,size 2>$null
    if ($LASTEXITCODE -ne 0) { $failed++; Log "FAIL list $($dir.Name)"; continue }
    $objects = @((($listed | Out-String) | ConvertFrom-Json).data)
    $bad = @($files | Where-Object { $f = $_; -not ($objects | Where-Object { $_.name -eq "$prefix$($f.Name)" -and [long]$_.size -eq $f.Length }) })
    if ($bad.Count -gt 0) { $failed++; Log "FAIL verify $($dir.Name): $($bad.Count) of $($files.Count) files missing or wrong size"; continue }
    Add-Content $DONE_FILE $dir.Name
    Log "ok $($dir.Name): $($files.Count) files, $([Math]::Round(($files | Measure-Object Length -Sum).Sum / 1KB)) KB"
}
if ($todo.Count -eq 0) { Log "ok nothing new" }
exit ([int]($failed -gt 0))
