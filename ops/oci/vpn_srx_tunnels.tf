# ── Tunnel management for the BikoFW-SRX IPSec connection ─────────────────────
data "oci_core_ipsec_connection_tunnels" "srx" {
  ipsec_id   = oci_core_ipsec.srx.id
  depends_on = [oci_core_ipsec.srx]
}

resource "oci_core_ipsec_connection_tunnel_management" "srx_tunnel1" {
  ipsec_id  = oci_core_ipsec.srx.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.srx.ip_sec_connection_tunnels[0].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "srx-tunnel-1"
  shared_secret = var.srx_vpn_shared_secret

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
}

resource "oci_core_ipsec_connection_tunnel_management" "srx_tunnel2" {
  ipsec_id  = oci_core_ipsec.srx.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.srx.ip_sec_connection_tunnels[1].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "srx-tunnel-2"
  shared_secret = var.srx_vpn_shared_secret

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
}
