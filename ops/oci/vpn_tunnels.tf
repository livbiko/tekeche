# ── Tunnel management — apply AFTER first terraform apply creates the IPSec connection ──
# To activate: Rename-Item vpn_tunnels.tf.disabled vpn_tunnels.tf; terraform apply

data "oci_core_ipsec_connection_tunnels" "main" {
  ipsec_id   = oci_core_ipsec.onprem.id
  depends_on = [oci_core_ipsec.onprem]
}


resource "oci_core_ipsec_connection_tunnel_management" "tunnel1" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "tekeche-tunnel-1"
  shared_secret = var.vpn_shared_secret

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
    custom_encryption_algorithm     = "AES_256_GCM"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP14"
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel2" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[1].id

  routing       = "STATIC"
  ike_version   = "V2"
  display_name  = "tekeche-tunnel-2"
  shared_secret = var.vpn_shared_secret

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
    custom_encryption_algorithm     = "AES_256_GCM"
    lifetime                        = 3600
    is_pfs_enabled                  = true
    dh_group                        = "GROUP14"
  }
}
