# ── Livbiko Palo Alto VM-Series — compute instance ─────────────────────────────
# Marketplace image: Palo Alto Networks VM-Series Bundle1 (PAYGO), package
# 11.2.10-h6-Bundle1-500, $1.80/instance-hour software fee on top of the
# underlying compute cost. Agreements (Oracle ToU, Palo Alto partner terms,
# PII data-sharing notice) accepted via `oci marketplace accepted-agreement
# create` prior to this apply -- required before any launch from this image.
#
# 3 VNICs, matching Palo Alto's documented interface pattern:
#   primary (mgmt)      -- private, Bastion-only, no public IP
#   secondary (untrust) -- public, becomes the IPSec tunnel endpoint once the
#                           on-prem PA exists (Phase 3/4, not done yet)
#   secondary (trust)   -- private, faces the eventual LPG toward tekeche-vcn
#
# Default admin login on first boot: username `admin`, password = this
# instance's OCID (standard Palo Alto Marketplace behavior on OCI/AWS/Azure)
# -- must be changed on first login. No custom bootstrap XML here; interface
# assignment (mgmt/untrust/trust -> eth0/eth1/eth2), zones, and the VTAP
# capture target below are configured through the PAN-OS UI/API after boot,
# per Phase 2 of the integration plan.

resource "oci_core_instance" "livbiko_pa" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "livbiko-pa-vmseries"
  shape               = var.livbiko_pa_shape

  shape_config {
    ocpus         = var.livbiko_pa_ocpus
    memory_in_gbs = var.livbiko_pa_memory_gb
  }

  source_details {
    source_type = "image"
    source_id   = var.livbiko_pa_image_id
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.livbiko_pa_mgmt.id
    display_name           = "livbiko-pa-mgmt-vnic"
    assign_public_ip       = false
    skip_source_dest_check = true
  }

  # Launched via the OCI Console's Marketplace flow (the CLI's Partner Image
  # Catalog subscription step errored -- see livbiko_pa_image_id's comment),
  # then imported here. agent_config/freeform_tags/source_details are left
  # as the console set them rather than fought back to a different value on
  # an already-running, billing instance.
  lifecycle {
    ignore_changes = [agent_config, freeform_tags, source_details]
  }
}

resource "oci_core_vnic_attachment" "livbiko_pa_untrust" {
  instance_id  = oci_core_instance.livbiko_pa.id
  display_name = "livbiko-pa-untrust-attach"

  create_vnic_details {
    subnet_id              = oci_core_subnet.livbiko_pa_untrust.id
    display_name           = "livbiko-pa-untrust-vnic"
    assign_public_ip       = true
    skip_source_dest_check = true
  }
}

resource "oci_core_vnic_attachment" "livbiko_pa_trust" {
  instance_id  = oci_core_instance.livbiko_pa.id
  display_name = "livbiko-pa-trust-attach"

  create_vnic_details {
    subnet_id              = oci_core_subnet.livbiko_pa_trust.id
    display_name           = "livbiko-pa-trust-vnic"
    private_ip             = var.livbiko_pa_trust_private_ip
    assign_public_ip       = false
    skip_source_dest_check = true
  }
}
