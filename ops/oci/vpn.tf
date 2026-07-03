# ── Customer Premises Equipment (your on-prem router) ─────────────────────────
resource "oci_core_cpe" "onprem" {
  compartment_id = var.compartment_id
  ip_address     = var.onprem_public_ip
  display_name   = "${var.project_name}-onprem-cpe"
  cpe_device_shape_id = data.oci_core_cpe_device_shapes.all.cpe_device_shapes[
    index(data.oci_core_cpe_device_shapes.all.cpe_device_shapes[*].cpe_device_info[0].vendor, var.cpe_vendor)
  ].cpe_device_shape_id
}

data "oci_core_cpe_device_shapes" "all" {}

# ── IPSec Connection ──────────────────────────────────────────────────────────
resource "oci_core_ipsec" "onprem" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.onprem.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-ipsec"

  static_routes  = [var.onprem_cidr]

  # OCI creates 2 tunnels for redundancy automatically
}

# ── Tunnel 1 configuration ────────────────────────────────────────────────────
data "oci_core_ipsec_connections" "tunnels" {
  compartment_id = var.compartment_id
  depends_on     = [oci_core_ipsec.onprem]
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel1" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].id

  routing = "STATIC"

  ike_version    = "V2"
  display_name   = "${var.project_name}-tunnel-1"

  shared_secret  = var.vpn_shared_secret

  phase_one_details {
    is_custom_phase_one_config = true
    authentication_algorithm   = "SHA2_256"
    encryption_algorithm       = "AES_256_CBC"
    diffie_hellman_group       = "GROUP14"
    lifetime_in_seconds        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config = true
    authentication_algorithm   = "HMAC_SHA2_256_128"
    encryption_algorithm       = "AES_256_GCM"
    lifetime_in_seconds        = 3600
    is_pfs_enabled             = true
    dh_group                   = "GROUP14"
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel2" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[1].id

  routing      = "STATIC"
  ike_version  = "V2"
  display_name = "${var.project_name}-tunnel-2"
  shared_secret = var.vpn_shared_secret

  phase_one_details {
    is_custom_phase_one_config = true
    authentication_algorithm   = "SHA2_256"
    encryption_algorithm       = "AES_256_CBC"
    diffie_hellman_group       = "GROUP14"
    lifetime_in_seconds        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config = true
    authentication_algorithm   = "HMAC_SHA2_256_128"
    encryption_algorithm       = "AES_256_GCM"
    lifetime_in_seconds        = 3600
    is_pfs_enabled             = true
    dh_group                   = "GROUP14"
  }
}

data "oci_core_ipsec_connection_tunnels" "main" {
  ipsec_id = oci_core_ipsec.onprem.id
}

# ── Windows RRAS config (rendered for copy-paste) ─────────────────────────────
# Apply on-prem with:
#   Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination <tunnel1_ip> ...
#   Set-VpnS2SInterface  -Name "OCI-Tunnel1" -AuthenticationMethod PSKOnly -SharedSecret <secret>
#   Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination <tunnel2_ip> ...
#
# Then add static route:
#   New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1" -RouteMetric 1
