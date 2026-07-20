# ── Livbiko Palo Alto VM-Series — traffic mirroring (VTAP) ─────────────────────
# Passive mirror, per the approved deployment mode: the PA VM-Series receives
# a copy of traffic, it does not sit inline. Wired up now so it's ready --
# but honestly, there is nothing to mirror yet: this VCN currently contains
# only the PA instance itself. This becomes meaningful once either (a) real
# Livbiko workloads land in this VCN, or (b) the on-prem tunnel (Phase 3/4 of
# the integration plan) exists and traffic starts flowing through the
# untrust interface. Scope was deliberately kept to livbiko-pa-vcn only for
# this pass -- extending capture to tekeche-vcn's real production traffic was
# explicitly deferred, not assumed.
#
# The OCI side (capture filter + VTAP target) is Terraform-managed. Actually
# decapsulating and inspecting the mirrored VXLAN stream is configured on the
# PAN-OS side (a tap-zone interface) after boot -- not something Terraform
# reaches into the firewall to configure.

resource "oci_core_capture_filter" "livbiko_pa_mirror_all" {
  compartment_id = var.compartment_id
  display_name   = "livbiko-pa-mirror-all"
  filter_type    = "VTAP"

  vtap_capture_filter_rules {
    traffic_direction = "INGRESS"
    rule_action       = "INCLUDE"
    protocol          = "all"
    source_cidr       = "0.0.0.0/0"
    destination_cidr  = "0.0.0.0/0"
  }
  vtap_capture_filter_rules {
    traffic_direction = "EGRESS"
    rule_action       = "INCLUDE"
    protocol          = "all"
    source_cidr       = "0.0.0.0/0"
    destination_cidr  = "0.0.0.0/0"
  }
}

resource "oci_core_vtap" "livbiko_pa_trust_mirror" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.livbiko_pa.id
  display_name      = "livbiko-pa-trust-vtap"
  capture_filter_id = oci_core_capture_filter.livbiko_pa_mirror_all.id

  source_id   = oci_core_subnet.livbiko_pa_trust.id
  source_type = "SUBNET"

  target_id   = oci_core_vnic_attachment.livbiko_pa_trust.vnic_id
  target_type = "VNIC"

  is_vtap_enabled = true
}
