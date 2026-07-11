# ── IAM for OKE ─────────────────────────────────────────────────────────────
# Standard, Oracle-documented required policy for the OKE service to manage
# resources on behalf of the cluster (LB provisioning for Service type
# LoadBalancer, block volume provisioning for PVCs, etc.). Scoping this
# tighter than "manage all-resources" breaks core OKE functionality — this
# is what Oracle's own OKE setup docs specify, not an over-broad grant.
resource "oci_identity_policy" "oke_service_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-oke-service-policy"
  description    = "Allow OKE service to manage resources in the tekeche compartment"

  statements = [
    "Allow service OKE to manage all-resources in compartment id ${var.compartment_id}",
  ]
}

# ── Dynamic group for worker node instances — OCIR pull access ────────────────
resource "oci_identity_dynamic_group" "oke_nodes" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-oke-nodes-dg"
  description    = "OKE worker node instances (Phase 1 node pool)"

  # instance.pool.id turned out not to match anything real (confirmed via a
  # 403 "not authorized" on OCIR from an actual node instance during Phase 2
  # push testing — see project_ocir_auth_token_blocked memory). OKE-created
  # instances carry a defined tag Oracle-Tags.CreatedBy=oke automatically
  # (confirmed via `oci compute instance get` on a real node pool instance),
  # which is the reliable match.
  matching_rule = "ALL {instance.compartment.id = '${var.compartment_id}', tag.Oracle-Tags.CreatedBy.value = 'oke'}"
}

resource "oci_identity_policy" "oke_nodes_ocir_pull" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-oke-nodes-ocir-policy"
  description    = "Allow OKE worker nodes to pull and push images to OCIR (push needed for the Phase 2 build node, per project_ocir_auth_token_blocked memory — user-level Auth Tokens are rejected in this tenancy for an unresolved reason)"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage repos in compartment id ${var.compartment_id}",
  ]
}
