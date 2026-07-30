# ── IAM for VTAP (traffic mirroring) ───────────────────────────────────────────
# The earlier "allow service vtap to ..." theory was wrong: that 404's error
# text ("service Core Vtap need policy to access this resource") is OCI's
# generic templated wording for any Core-API authorization failure (same
# phrasing shows up for plain VCN creation failures too, per a Cloud
# Customer Connect report) -- it does not mean a real service-principal
# grant is needed, and "vtap" was correctly rejected as an invalid service
# name for exactly that reason.
#
# Real cause: OCI's policy reference lists `vtaps` as its own individual
# resource type, explicitly NOT part of the `virtual-network-family`
# aggregate. Administrators already holds tenancy-wide "manage all-resources"
# (confirmed via `oci iam policy list`), which should cover this, but OCI's
# `all-resources` aggregate is known to lag behind for newer individual
# resource types -- this explicit grant closes that gap.
resource "oci_identity_policy" "vtap_group_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-vtap-group-policy"
  description    = "Explicit vtaps grant for Administrators in the UK compartment (all-resources doesn't yet cover this individual resource type)"

  statements = [
    "Allow group Administrators to manage vtaps in compartment id ${var.compartment_id}",
  ]
}

# 2026-07-22: per OCI's own policy reference (Details for Verb + Resource-Type
# Combinations), CreateVtap requires VTAP_CREATE *and* CAPTURE_FILTER_ATTACH
# (in the capture filter's compartment) *and* VCN_ATTACH (in the VCN's
# compartment) -- capture-filters is a separate resource-type from vtaps.
# The capture filter itself (oci_core_capture_filter.livbiko_pa_mirror_all)
# already created fine under all-resources, but CAPTURE_FILTER_ATTACH is a
# distinct permission from CAPTURE_FILTER_CREATE and may lag the aggregate
# the same way vtaps did. Explicit grant closes that gap if so.
resource "oci_identity_policy" "capture_filter_group_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-capture-filter-group-policy"
  description    = "Explicit capture-filters grant for Administrators in the UK compartment (CreateVtap needs CAPTURE_FILTER_ATTACH specifically)"

  statements = [
    "Allow group Administrators to manage capture-filters in compartment id ${var.compartment_id}",
  ]
}
