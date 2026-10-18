# Deploy-AlertFix-BikoDC1.ps1 -- roll tekeche-api a1c0446 (security monitor alert e-mail flood fix, Build #62) to BikoDC1.
# Run it yourself on BikoDC (as Administrator). Prepared 2026-10-18; not run by Claude (remote writes are not
# permitted in its session).
# Checked beforehand: BikoDC1's securityMonitor.js was identical to BikoDC's pre-fix version (only line endings
# differed), so this copy changes nothing but the alert fix.
# Rollback: copy securityMonitor.js.bak-20261018 back over the file and reload tekeche-api on BikoDC1.
$ErrorActionPreference = 'Stop'
$src = 'C:\inetpub\wwwroot\tekeche\tekeche-api\src\middleware\securityMonitor.js'
$dst = '\\BikoDC1\c$\inetpub\wwwroot\tekeche\tekeche-api\src\middleware\securityMonitor.js'

Copy-Item $dst "$dst.bak-20261018" -Force
Copy-Item $src $dst -Force
if ((Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash) { throw 'copy mismatch' }
Write-Host 'Copied (backup: securityMonitor.js.bak-20261018). Now reload on BikoDC1 itself:' -ForegroundColor Green
Write-Host '  on BikoDC1:  pm2 reload tekeche-api      (reload, not restart; it takes about 90 s to answer again)'
Write-Host '  then check:  curl http://BikoDC1:5000/health   -> {"status":"ok",...}'
