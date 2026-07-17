# ── Key outputs after `terraform apply` ───────────────────────────────────────

output "lb_public_ip" {
  description = "OCI Network Load Balancer public IP — point api.tekeche.com DNS here"
  value       = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
}

output "standby_private_ip" {
  description = "OCI hot-standby VM private IP (VPN reachable from on-prem)"
  value       = oci_core_instance.standby.private_ip
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
  description = "Vault OCID — needed when uploading secrets"
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
  description = "OCI health monitor OCID for the LB"
  value       = oci_health_checks_http_monitor.lb_health.id
}

output "vpn_tunnel1_ip" {
  description = "OCI IPSec tunnel 1 IP — configure as VPN peer on Windows RRAS"
  value       = "140.238.94.206"
}

output "vpn_tunnel2_ip" {
  description = "OCI IPSec tunnel 2 IP — redundant peer"
  value       = "152.67.132.125"
}

output "next_steps" {
  description = "Remaining manual steps"
  value       = <<-EOT

    ── REMAINING STEPS ───────────────────────────────────────────────────────────

    1. RRAS + VPN (HIGH RISK — reboot required, ~10 min downtime):
       Install-WindowsFeature RemoteAccess, DirectAccess-VPN, Routing -IncludeManagementTools -Restart
       # After reboot:
       Install-RemoteAccess -VpnType VpnS2S
       Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination "140.238.94.206" -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret "VfdTacUMLJBj8rE96DbKku70ngNAxWHezSORCPp1" -IdleDisconnectSeconds 0 -NumberOfTries 0
       Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination "152.67.132.125" -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret "VfdTacUMLJBj8rE96DbKku70ngNAxWHezSORCPp1" -IdleDisconnectSeconds 0 -NumberOfTries 0
       New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1" -RouteMetric 1
       Connect-VpnS2SInterface -Name "OCI-Tunnel1"
       Connect-VpnS2SInterface -Name "OCI-Tunnel2"

    2. MongoDB RS (after VPN is UP):
       rs.add({ host: "10.0.2.10:27017", priority: 0, votes: 0 })

    3. Verify end-to-end:
       curl https://api.tekeche.com/health
       # expect: {"status":"ok","db":"connected"}

    4. Failover test:
       # From OCI Console: LB → Backend Sets → set on-prem backend to drain
       # Verify /health still returns 200 (served from OCI standby)
       # Then un-drain and confirm traffic returns to on-prem

  EOT
}
