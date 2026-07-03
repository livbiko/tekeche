# ── OCI Vault — secrets management for tekeche-api .env ───────────────────────

resource "oci_kms_vault" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-vault"
  vault_type     = "DEFAULT"

  freeform_tags = {
    project = var.project_name
  }
}

# ── Master Encryption Key (AES-256) ───────────────────────────────────────────
resource "oci_kms_key" "app_key" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-app-key"
  management_endpoint = oci_kms_vault.main.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32   # 256-bit
  }

  protection_mode = "HSM"

  freeform_tags = {
    project = var.project_name
  }
}

# ── Secret: tekeche-api .env file ─────────────────────────────────────────────
# The secret content is a base64-encoded .env file.
# Manage it outside of Terraform (rotate without re-deploying infra):
#
#   base64 -w 0 /path/to/.env > /tmp/env_b64.txt
#   oci vault secret create-base64 \
#     --compartment-id <compartment_ocid> \
#     --secret-name tekeche-api-env \
#     --vault-id <vault_ocid> \
#     --key-id <key_ocid> \
#     --secret-content-content $(cat /tmp/env_b64.txt)
#
# Then set app_env_secret_id in terraform.tfvars to the returned secret OCID.
# The cloud_init.tpl script fetches it with `oci secrets secret-bundle get`.

# ── IAM Dynamic Group — lets the standby VM read secrets ──────────────────────
resource "oci_identity_dynamic_group" "standby_vm" {
  compartment_id = var.compartment_id   # must be tenancy root for identity resources
  name           = "${var.project_name}-standby-dg"
  description    = "OCI instances that run the tekeche-api standby"

  matching_rule = "ANY { instance.id = '${oci_core_instance.standby.id}' }"
}

# ── IAM Policy — standby VM can read secrets from the vault ───────────────────
resource "oci_identity_policy" "standby_vault_read" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-standby-vault-policy"
  description    = "Allow standby VM to read app secrets from Vault"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.standby_vm.name} to read secret-bundles in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.standby_vm.name} to use keys in compartment id ${var.compartment_id}"
  ]
}
