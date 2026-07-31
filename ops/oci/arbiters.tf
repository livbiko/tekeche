# ── MongoDB rs0 extra cloud voters (1 arbiter + 1 data-bearing secondary) ──
# Added 2026-07-31: rs0 had 3 voting members (BikoDC, BikoDC1, OCI standby),
# where BikoDC+BikoDC1 together held 2 of those 3 votes. Losing both on-prem
# nodes at once (as happened during the 2026-07-31 power-off drill) dropped
# the replica set below majority even though the OCI standby was healthy --
# and its priority:0 meant it couldn't have been elected primary anyway.
#
# Original plan was 2 data-free arbiters (standby + 2 arbiters = 3 of 5
# votes), but MongoDB rejects a second arbiter by default ("Multiple
# arbiters are not allowed unless ... allowMultipleArbiters=true") -- a real
# safety guard against ambiguous majority-commit semantics with data-free
# voters, not worth overriding. mongo_arbiter_b ended up added to rs0 as a
# real data-bearing secondary (priority:0, non-electable, full initial sync)
# instead of a true arbiter -- same VM/cloud-init either way, since
# arbiter-vs-secondary is decided entirely by the rs.add() call, not local
# mongod config. Both resource names kept as-is (renaming would force a
# destroy/recreate) despite mongo_arbiter_b no longer being a true arbiter.
# End state: standby + arbiter_a + arbiter_b = 3 of 5 total votes, so OCI
# alone can still reach majority if on-prem is fully down.
# See ops/MAINTENANCE_LOG.md 2026-07-31 for the incident this fixes.
#
# bindIp is 0.0.0.0 (not a specific private IP like the standby's mongod.conf
# uses) -- access is already scoped by the security-list rules (on-prem CIDR
# + intra-subnet only) plus keyfile auth, so a per-instance IP substitution
# in cloud-init isn't worth the added complexity here.
locals {
  arbiter_cloud_init = <<-EOT
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -qq
    apt-get install -y -qq curl gnupg

    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.3 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.3.list
    apt-get update -qq && apt-get install -y mongodb-org

    # Must be byte-identical to on-prem's keyfile -- same replica set, same
    # internal cluster auth requirement as the standby (see compute.tf).
    cat > /etc/mongo-keyfile <<'KEYFILE'
    ${var.mongodb_keyfile_content}
    KEYFILE
    chown mongodb:mongodb /etc/mongo-keyfile
    chmod 600 /etc/mongo-keyfile

    cat > /etc/mongod.conf <<'MONGOCFG'
    storage:
      dbPath: /var/lib/mongodb
    net:
      port: 27017
      bindIp: 0.0.0.0
    replication:
      replSetName: "${var.mongodb_rs_name}"
    security:
      authorization: enabled
      keyFile: /etc/mongo-keyfile
    MONGOCFG

    systemctl enable mongod && systemctl start mongod

    # Same OS-level firewall gap as the standby -- OCI Security Lists are a
    # separate outer layer and don't override the image's default iptables.
    iptables -I INPUT -p tcp --dport 27017 -j ACCEPT
    netfilter-persistent save || true

    echo "Mongo arbiter ready" > /var/log/tekeche-init.log
  EOT
}

resource "oci_core_instance" "mongo_arbiter_a" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
  display_name        = "${var.project_name}-mongo-arbiter-a"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu2204.images[0].id
    boot_volume_size_in_gbs = 50
    kms_key_id              = oci_kms_key.app_key.id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    private_ip       = "10.0.2.20"
    assign_public_ip = false
    display_name     = "${var.project_name}-mongo-arbiter-a-vnic"
    hostname_label   = "${var.project_name}-mongo-arbiter-a"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.arbiter_cloud_init)
  }

  freeform_tags = {
    project = var.project_name
    role    = "mongo-arbiter"
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id, metadata]
  }
}

resource "oci_core_instance" "mongo_arbiter_b" {
  compartment_id      = var.compartment_id
  # AD-3 (index 2) rejected LaunchInstance with a 404 NotAuthorizedOrNotFound
  # for this shape/compartment on 2026-07-31 -- falling back to AD-1 (same as
  # the standby) rather than spend more time chasing the AD-3 gap tonight.
  # Still gives 2 of 3 ADs represented across the 3 OCI-side rs0 voters.
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-mongo-arbiter-b"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu2204.images[0].id
    boot_volume_size_in_gbs = 50
    kms_key_id              = oci_kms_key.app_key.id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    private_ip       = "10.0.2.21"
    assign_public_ip = false
    display_name     = "${var.project_name}-mongo-arbiter-b-vnic"
    hostname_label   = "${var.project_name}-mongo-arbiter-b"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.arbiter_cloud_init)
  }

  freeform_tags = {
    project = var.project_name
    role    = "mongo-arbiter"
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id, metadata]
  }
}

output "mongo_arbiter_ips" {
  description = "Private IPs of the two MongoDB arbiter VMs"
  value       = [oci_core_instance.mongo_arbiter_a.private_ip, oci_core_instance.mongo_arbiter_b.private_ip]
}
