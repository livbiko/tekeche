# ── Public compartment — no security zone, lives at tenancy root ───────────────
# The "UK" compartment has a security zone that blocks IGW and requires KMS on
# boot volumes. Public resources (VCN, IGW, LB) live here instead.
resource "oci_identity_compartment" "pub" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-pub"
  description    = "Tekeche public zone — VCN, IGW, LB (no security zone constraints)"
  enable_delete  = true

  freeform_tags = {
    project = var.project_name
  }
}
