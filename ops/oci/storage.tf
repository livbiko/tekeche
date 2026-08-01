# ── Uploads bucket (driver KYC documents + general /uploads) ──────────────────
# Shared object storage so KYC document uploads survive failover between
# on-prem and the OCI standby -- previously each node wrote to its own local
# disk (tekeche-api/src/controllers/driver.controller.js), so a file uploaded
# to one node was invisible on the other. Read via the Object Storage
# S3-compatible API (same approach as the existing `velero` bucket below),
# authenticated with a Customer Secret Key generated separately (not a
# Terraform resource, same reasoning as Velero's -- keep the one-time-shown
# secret value out of tfstate).
resource "oci_objectstorage_bucket" "uploads" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${var.project_name}-uploads"
  access_type    = "NoPublicAccess"
  kms_key_id     = oci_kms_key.app_key.id
}

output "uploads_bucket_name" {
  value = oci_objectstorage_bucket.uploads.name
}

output "uploads_bucket_s3_endpoint" {
  value = "https://${data.oci_objectstorage_namespace.this.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
}
