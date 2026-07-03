# ── Key outputs after `terraform apply` ───────────────────────────────────────

output "lb_public_ip" {
  description = "OCI Load Balancer public IP — point api.tekeche.com DNS here (or let dns.tf manage it)"
  value       = oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address
}

output "standby_private_ip" {
  description = "OCI hot-standby VM private IP (VPN reachable from on-prem)"
  value       = oci_core_instance.standby.private_ip
}

output "vpn_tunnel1_ip" {
  description = "OCI IPSec tunnel 1 IP — configure as VPN peer on Windows RRAS"
  value       = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].vpn_ip
}

output "vpn_tunnel2_ip" {
  description = "OCI IPSec tunnel 2 IP — redundant peer"
  value       = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[1].vpn_ip
}

output "bastion_id" {
  description = "OCI Bastion OCID — use to create SSH sessions into the private subnet"
  value       = oci_bastion_bastion.main.id
}

output "vault_management_endpoint" {
  description = "KMS management endpoint — needed for key operations"
  value       = oci_kms_vault.main.management_endpoint
}

output "vault_ocid" {
  description = "Vault OCID — needed when uploading secrets via oci-cli"
  value       = oci_kms_vault.main.id
}

output "master_key_ocid" {
  description = "AES-256 master key OCID — needed when creating secrets"
  value       = oci_kms_key.app_key.id
}

output "dns_zone_id" {
  description = "OCI DNS zone OCID"
  value       = oci_dns_zone.tekeche.id
}

output "health_monitor_id" {
  description = "HTTP health monitor OCID for the OCI LB"
  value       = oci_health_checks_http_monitor.lb_health.id
}

# ── Post-apply checklist ───────────────────────────────────────────────────────
output "next_steps" {
  description = "Manual steps required after terraform apply"
  value       = <<-EOT

    ── POST-APPLY CHECKLIST ──────────────────────────────────────────────────────

    1. VPN — configure Windows RRAS on-prem:
       Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination <vpn_tunnel1_ip>
       Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination <vpn_tunnel2_ip>
       (use shared secret from var.vpn_shared_secret)
       New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1"

    2. MongoDB RS — add OCI standby as replica member from on-prem mongosh:
       rs.add({ host: "10.0.2.10:27017", priority: 0, votes: 0 })

    3. Vault secret — upload tekeche-api .env:
       base64 -w 0 /path/to/.env > /tmp/env_b64.txt
       oci vault secret create-base64 \
         --compartment-id <compartment_ocid> \
         --secret-name tekeche-api-env \
         --vault-id <vault_ocid> \
         --key-id <master_key_ocid> \
         --secret-content-content $(cat /tmp/env_b64.txt)
       Then set app_env_secret_id = "<secret_ocid>" in terraform.tfvars and re-apply.

    4. DNS — if not using OCI DNS, point api.tekeche.com A record to lb_public_ip
       at your registrar (TTL 30s).

    5. LB cert — obtain cert for api.tekeche.com in OCI Certificates service,
       set lb_cert_id = "<cert_ocid>" in terraform.tfvars and re-apply.

    6. Verify:
       curl https://api.tekeche.com/health
       # expect: {"status":"ok"}

    7. Failover test:
       # Un-drain OCI standby in LB console, stop on-prem app,
       # verify /health still returns 200 from OCI standby.
       # Then re-drain standby and restart on-prem.

  EOT
}
