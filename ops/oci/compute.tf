# ── Cloud-init script for the hot standby VMs ─────────────────────────────────
# Templated (cloud_init.tpl) rather than inlined so a second OCI compute node
# (standby2, mirroring this one for Phase 2 OCI-side redundancy -- see
# project_oci_api_self_sufficiency memory) can reuse the identical
# provisioning logic with just a different private_ip and Redis role.
locals {
  github_clone_url = var.github_pat != "" ? replace(var.github_repo_url, "https://", "https://x-access-token:${var.github_pat}@") : var.github_repo_url

  cloud_init_standby = templatefile("${path.module}/cloud_init.tpl", {
    private_ip              = var.standby_private_ip
    mongodb_keyfile_content = var.mongodb_keyfile_content
    mongodb_rs_name         = var.mongodb_rs_name
    onprem_nlb_vip          = var.onprem_nlb_vip
    github_clone_url        = local.github_clone_url
    app_env_secret_id       = var.app_env_secret_id
    standby_ocpus           = var.standby_ocpus
    run_redis_data_node     = true
  })

  # standby2 is app + Mongo-voter only, no local Redis/Sentinel daemon -- it
  # reaches the existing 7-node Sentinel mesh as a client via SENTINEL_HOSTS
  # (already in the shared Vault .env), same as any other app-hosting node.
  # Reproducing the full ad-hoc Sentinel setup from Build #45/46 in cloud-init
  # is real risk for no benefit here since a 4th Redis data replica isn't
  # needed for quorum.
  cloud_init_standby2 = templatefile("${path.module}/cloud_init.tpl", {
    private_ip              = var.standby2_private_ip
    mongodb_keyfile_content = var.mongodb_keyfile_content
    mongodb_rs_name         = var.mongodb_rs_name
    onprem_nlb_vip          = var.onprem_nlb_vip
    github_clone_url        = local.github_clone_url
    app_env_secret_id       = var.app_env_secret_id
    standby_ocpus           = var.standby2_ocpus
    run_redis_data_node     = false
  })
}

# ── Hot standby compute instance ──────────────────────────────────────────────
resource "oci_core_instance" "standby" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-standby"
  shape               = var.standby_shape

  shape_config {
    ocpus         = var.standby_ocpus
    memory_in_gbs = var.standby_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = var.standby_image_id != "" ? var.standby_image_id : data.oci_core_images.ubuntu2204.images[0].id
    boot_volume_size_in_gbs = 50
    kms_key_id              = oci_kms_key.app_key.id
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private.id
    private_ip             = var.standby_private_ip
    assign_public_ip       = false
    display_name           = "${var.project_name}-standby-vnic"
    hostname_label         = "${var.project_name}-standby"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init_standby)
  }

  freeform_tags = {
    project = var.project_name
    role    = "hot-standby"
  }

  lifecycle {
    # metadata (user_data/cloud-init) is ForceNew in the OCI provider -- if not
    # ignored here, editing the cloud-init template (e.g. the PM2 cluster-mode
    # change) would force a full instance replace on the next apply: fresh
    # boot volume, full MongoDB resync, LB backend re-registration. Cloud-init
    # only runs on first boot anyway, so template edits are meant to describe
    # what a *future* rebuild gets, not to be pushed live to this instance.
    ignore_changes = [source_details[0].source_id, metadata]
  }
}

# ── Second OCI compute node (Phase 2: OCI-side redundancy) ────────────────────
# Mirrors `standby` above (Node/PM2/Nginx + Mongo rs0 voting member) so the
# OCI side survives losing either one of its own nodes, not just being a
# single-VM failover target for on-prem. No local Redis/Sentinel daemon --
# see cloud_init.tpl's run_redis_data_node note.
resource "oci_core_instance" "standby2" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-standby2"
  shape                = var.standby2_shape

  shape_config {
    ocpus         = var.standby2_ocpus
    memory_in_gbs = var.standby2_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = var.standby_image_id != "" ? var.standby_image_id : data.oci_core_images.ubuntu2204.images[0].id
    boot_volume_size_in_gbs = 50
    kms_key_id              = oci_kms_key.app_key.id
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private.id
    private_ip             = var.standby2_private_ip
    assign_public_ip       = false
    display_name           = "${var.project_name}-standby2-vnic"
    hostname_label         = "${var.project_name}-standby2"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init_standby2)
  }

  freeform_tags = {
    project = var.project_name
    role    = "hot-standby-2"
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id, metadata]
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu2204" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.standby_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

