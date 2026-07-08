# ── Tunnel management for the MX68 IPSec connection ───────────────────────────
data "oci_core_ipsec_connection_tunnels" "mx68" {
  ipsec_id   = oci_core_ipsec.mx68.id
  depends_on = [oci_core_ipsec.mx68]
}

resource "oci_core_ipsec_connection_tunnel_management" "mx68_tunnel1" {
  ipsec_id  = oci_core_ipsec.mx68.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.mx68.ip_sec_connection_tunnels[0].id

  routing                 = "STATIC"
  ike_version             = "V2"
  display_name            = "mx68-tunnel-1"
  shared_secret           = var.mx68_vpn_shared_secret
  nat_translation_enabled = "ENABLED"

  phase_one_details {
    is_custom_phase_one_config      = true
    custom_authentication_algorithm = "SHA2_256"
    custom_encryption_algorithm     = "AES_256_CBC"
    custom_dh_group                 = "GROUP14"
    lifetime                        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    custom_authentication_algorithm = "HMAC_SHA2_256_128"
    custom_encryption_algorithm     = "AES_256_CBC"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP14"
  }

  encryption_domain_config {
    oracle_traffic_selector = ["10.0.0.0/16"]
    cpe_traffic_selector    = ["192.168.128.0/24"]
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "mx68_tunnel2" {
  ipsec_id  = oci_core_ipsec.mx68.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.mx68.ip_sec_connection_tunnels[1].id

  routing                 = "STATIC"
  ike_version             = "V2"
  display_name            = "mx68-tunnel-2"
  shared_secret           = var.mx68_vpn_shared_secret
  nat_translation_enabled = "ENABLED"

  phase_one_details {
    is_custom_phase_one_config      = true
    custom_authentication_algorithm = "SHA2_256"
    custom_encryption_algorithm     = "AES_256_CBC"
    custom_dh_group                 = "GROUP14"
    lifetime                        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    custom_authentication_algorithm = "HMAC_SHA2_256_128"
    custom_encryption_algorithm     = "AES_256_CBC"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP14"
  }

  encryption_domain_config {
    oracle_traffic_selector = ["10.0.0.0/16"]
    cpe_traffic_selector    = ["192.168.128.0/24"]
  }
}
