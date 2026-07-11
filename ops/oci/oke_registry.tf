# ── OCIR (Container Registry) ─────────────────────────────────────────────────
# The registry itself is automatic per-tenancy/region — only repositories are
# explicit resources. Only tekeche-api's repo is created now (Phase 1/2 scope);
# other apps get their own repo in their respective migration phase.
resource "oci_artifacts_container_repository" "tekeche_api" {
  compartment_id = var.compartment_id
  display_name   = "tekeche-api"
  is_public      = false
}
