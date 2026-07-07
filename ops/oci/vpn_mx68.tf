# ── Customer Premises Equipment — Meraki MX68 (separate LAN, same site) ───────
resource "oci_core_cpe" "mx68" {
  compartment_id = var.compartment_id
  ip_address     = var.mx68_public_ip
  display_name   = "${var.project_name}-mx68-cpe"
}

# ── IPSec Connection ──────────────────────────────────────────────────────────
resource "oci_core_ipsec" "mx68" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.mx68.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-mx68-ipsec"
  static_routes  = [var.mx68_lan_cidr]

  # Meraki sends its own public IP as IKE identity by default (no NAT quirk
  # like RRAS), so no cpe_local_identifier override needed here.
}
