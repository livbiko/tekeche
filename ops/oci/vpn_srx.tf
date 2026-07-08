# ── Customer Premises Equipment — BikoFW-SRX (dmz zone edge) ───────────────────
# Replaces the former RRAS tunnel's role for 192.168.1.0/24 -- RRAS itself was
# decommissioned 2026-07-08. Terminates on BikoFW-SRX's irb.50 interface
# (192.168.1.1, dmz zone) via a Hub Manager port-forward for UDP 500/4500.
resource "oci_core_cpe" "srx" {
  compartment_id = var.compartment_id
  ip_address     = var.onprem_public_ip
  display_name   = "${var.project_name}-srx-cpe"
}

# ── IPSec Connection ──────────────────────────────────────────────────────────
resource "oci_core_ipsec" "srx" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.srx.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-srx-ipsec"
  static_routes  = [var.onprem_cidr]

  # SRX is behind NAT and sends its dmz-zone IP as its IKE identity, not the
  # public IP -- same pattern as RRAS previously needed.
  cpe_local_identifier      = var.srx_local_identifier
  cpe_local_identifier_type = "IP_ADDRESS"
}
