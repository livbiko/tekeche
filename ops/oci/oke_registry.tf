# ── OCIR (Container Registry) ─────────────────────────────────────────────────
# The registry itself is automatic per-tenancy/region — only repositories are
# explicit resources. Repos must exist before a push succeeds (confirmed
# 2026-07-18 -- Kaniko's "checking push permission" failed with DENIED
# against tekeche-web/livbiko-web even though the oke-nodes dynamic group
# already has "manage repos" IAM rights, because the repo objects themselves
# didn't exist yet).
resource "oci_artifacts_container_repository" "tekeche_api" {
  compartment_id = var.compartment_id
  display_name   = "tekeche-api"
  is_public      = false
}

resource "oci_artifacts_container_repository" "tekeche_web" {
  compartment_id = var.compartment_id
  display_name   = "tekeche-web"
  is_public      = false
}

resource "oci_artifacts_container_repository" "livbiko_web" {
  compartment_id = var.compartment_id
  display_name   = "livbiko-web"
  is_public      = false
}
