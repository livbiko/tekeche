# Creates the tekeche-api-secrets Kubernetes Secret directly from the existing
# on-prem .env file's sensitive values, without ever writing them to a
# temporary file, a committed manifest, or a process command-line argument
# (values are assembled into a YAML manifest in memory and piped to
# `kubectl apply -f -` via stdin only).
#
# Deliberately NOT a static secret.yaml with placeholder values -- that
# pattern invites someone to commit real secrets into it by mistake.

$env:PATH += ";C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Links"
$env:KUBECONFIG = "C:\Users\Administrator\.kube\config"

$envPath = "C:\inetpub\wwwroot\tekeche\tekeche-api\.env"
$sensitiveKeys = @(
  "MONGODB_URI", "JWT_SECRET", "JWT_REFRESH_SECRET",
  "BREVO_SMTP_LOGIN", "BREVO_SMTP_KEY", "BREVO_API_KEY", "MAIL_USER", "MAIL_PASS",
  "PAYSTACK_SECRET_KEY", "PAYSTACK_PUBLIC_KEY",
  "GOOGLE_MAPS_API_KEY",
  "SECURITY_DASHBOARD_TOKEN", "APP_TOKEN", "MENU_ADMIN_KEY",
  "PAYMENT_GATEWAY_WEBHOOK_SECRET",
  "REDIS_URL"
)

$lines = Get-Content $envPath
$dataEntries = @()
foreach ($key in $sensitiveKeys) {
  $line = $lines | Where-Object { $_ -match "^$key=" } | Select-Object -First 1
  if ($line) {
    $value = $line.Substring($key.Length + 1)
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
    $dataEntries += "  ${key}: ${b64}"
  }
}

$manifest = @"
apiVersion: v1
kind: Secret
metadata:
  name: tekeche-api-secrets
  namespace: tekeche
type: Opaque
data:
$($dataEntries -join "`n")
"@

$manifest | & kubectl apply -f -
