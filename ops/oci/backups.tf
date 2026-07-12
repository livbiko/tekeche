# ── Boot volume backups ────────────────────────────────────────────────────────
# Scoped to the standby VM only. OKE worker nodes are deliberately NOT covered
# here: they're ephemeral/stateless members of a managed node pool (replaceable
# on demand, no unique local state worth snapshotting), and their boot volumes
# aren't stable Terraform-addressable resources the way a plain oci_core_instance's
# is. Actual OKE workload/cluster-state backup is handled by Velero instead (see
# the Velero manifests) - the right tool for that layer, not boot-volume snapshots.
data "oci_core_boot_volume_attachments" "standby" {
  compartment_id      = var.compartment_id
  availability_domain = oci_core_instance.standby.availability_domain
  instance_id         = oci_core_instance.standby.id
}

data "oci_core_volume_backup_policies" "bronze" {
  filter {
    name   = "display_name"
    values = ["bronze"]
  }
}

resource "oci_core_volume_backup_policy_assignment" "standby_boot_backup" {
  asset_id  = data.oci_core_boot_volume_attachments.standby.boot_volume_attachments[0].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.bronze.volume_backup_policies[0].id
}
