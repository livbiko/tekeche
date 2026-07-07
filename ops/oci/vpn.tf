# ── Customer Premises Equipment (your on-prem router) ─────────────────────────
resource "oci_core_cpe" "onprem" {
  compartment_id = var.compartment_id
  ip_address     = var.onprem_public_ip
  display_name   = "${var.project_name}-onprem-cpe"
  # cpe_device_shape_id omitted — OCI uses generic CPE config; use the
  # downloaded config from the Console or the RRAS commands in outputs.tf
}

# ── IPSec Connection ──────────────────────────────────────────────────────────
resource "oci_core_ipsec" "onprem" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.onprem.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-ipsec"
  static_routes  = [var.onprem_cidr]

  # RRAS is behind NAT; it sends IKE identity = its LAN IP (192.168.1.101),
  # not the public IP (81.130.238.41). Tell OCI to expect the LAN IP.
  cpe_local_identifier      = "192.168.1.101"
  cpe_local_identifier_type = "IP_ADDRESS"
}

# ── Tunnel configuration ──────────────────────────────────────────────────────
# The tunnel data source + management resources are in vpn_tunnels.tf.disabled.
# After first apply, enable them:
#   Rename-Item vpn_tunnels.tf.disabled vpn_tunnels.tf; terraform apply

# ── Windows RRAS config (rendered for copy-paste after apply) ─────────────────
# Use vpn_tunnel1_ip and vpn_tunnel2_ip from terraform output, then run:
#   Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination <vpn_tunnel1_ip> `
#     -Protocol IKEv2 -AuthenticationMethod PSKOnly `
#     -SharedSecret "<vpn_shared_secret>"
#   Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination <vpn_tunnel2_ip> `
#     -Protocol IKEv2 -AuthenticationMethod PSKOnly `
#     -SharedSecret "<vpn_shared_secret>"
#   New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1" -RouteMetric 1
