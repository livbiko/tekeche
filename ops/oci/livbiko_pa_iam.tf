# ── IAM for VTAP (traffic mirroring) ───────────────────────────────────────────
# Standard, Oracle-documented required policy for the VTAP service itself to
# write mirrored traffic into the target VNIC. Not the same as the calling
# user/group having "manage vtaps" rights (which the tenancy admin already
# has, and which was NOT the actual blocker) -- this is a service-principal
# grant, same pattern already used for Cloud Guard and OKE in this project.
# Confirmed via `oci iam policy list` that no existing policy covered this;
# apply of oci_core_vtap.livbiko_pa_trust_mirror failed 404 without it.
# NOT YET WORKING: "Allow service vtap to use ..." fails at apply time with
# `400-InvalidParameter, Service {vtap} does not exist` -- that exact
# service-principal name is rejected by this tenancy's Identity control
# plane. The Administrators group already holds tenancy-wide
# "manage all-resources" (confirmed via `oci iam policy list` against the
# tenancy root), which normally would cover this -- so the CreateVtap 404
# really does look like it needs its own service-principal grant, same
# family as the existing OKE/Cloud Guard/KMS service policies in this repo,
# just not under the name "vtap". Left disabled rather than guessing further
# against a live tenancy; the OCI Console's policy builder (autocomplete
# over valid service names) is the more reliable path here, same as how the
# marketplace image issue was resolved via Console instead of CLI.
#
# resource "oci_identity_policy" "vtap_service_policy" {
#   compartment_id = var.tenancy_ocid
#   name           = "${var.project_name}-vtap-service-policy"
#   description    = "Allow the VTAP service to write mirrored traffic into target VNICs in the UK compartment"
#
#   statements = [
#     "Allow service <CORRECT_NAME_TBD> to use virtual-network-family in compartment id ${var.compartment_id}",
#   ]
# }
