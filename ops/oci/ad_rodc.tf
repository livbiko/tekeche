# ── OCI-hosted Read-Only Domain Controller ────────────────────────────────────
# Gives OCI-hosted hosts a local AD replica (AD Site "OCI-London", already
# created out-of-band via PowerShell -- see ops/MAINTENANCE_LOG.md 2026-07-13
# "AD Phase A") instead of every Kerberos/LDAP round-trip crossing the
# BikoFW-SRX <-> OCI VPN. RODC (not writable): standard guidance for a DC in a
# less-trusted/more-exposed cloud location, especially since livbiko.local is
# shared with unrelated systems outside Tekeche (ALBANDC/GUIZODC/PASCALEDC/
# JUMPBOX -- see project_hadr_phase1_tier1_2026_07_12 memory). Never holds
# FSMO roles -- those stay on-prem (BikoDC) by design.
#
# Security-list rules for AD replication traffic already exist on
# oci_core_security_list.private (networking.tf) and the SRX-side VPN policy
# (DMZ-TO-OCI/OCI-TO-DMZ) is already "match application any" in both
# directions -- no additional firewall work needed for this VM to reach or be
# reached by the on-prem DCs.
#
# NOTE: this resource only provisions the VM. Domain-join + DC promotion
# (Install-ADDSDomainController -ReadOnlyReplica) is a separate, deliberate
# manual step over an OCI Bastion session -- not automated here, since that's
# the actual HIGH RISK moment (writes to the shared AD forest) and needs to
# happen under direct observation, not unattended at boot.
#
# WinRM is enabled via cloudbase-init user_data (not the Oracle Cloud Agent's
# Run Command plugin) -- the first VM build showed the agent's heartbeat
# freezing permanently a few minutes after boot (reproduced twice, including
# once right after a reboot specifically to clear it), making Run Command
# unusable. cloudbase-init is a separate, more fundamental first-boot
# mechanism (also responsible for hostname/network setup) and isn't affected
# by that bug.
locals {
  rodc_user_data = <<-EOT
    #ps1_sysnative
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force
    New-NetFirewallRule -Name WinRM-HTTPS -DisplayName "WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow -Direction Inbound -ErrorAction SilentlyContinue
  EOT
}

data "oci_core_images" "windows_server_2025" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2025 Standard"
  shape                    = var.rodc_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

resource "oci_core_instance" "rodc" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-rodc"
  shape               = var.rodc_shape

  shape_config {
    ocpus         = var.rodc_ocpus
    memory_in_gbs = var.rodc_memory_gb
  }

  source_details {
    source_type = "image"
    source_id   = var.rodc_image_id != "" ? var.rodc_image_id : data.oci_core_images.windows_server_2025.images[0].id
    kms_key_id  = oci_kms_key.app_key.id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    private_ip       = var.rodc_private_ip
    assign_public_ip = false
    display_name     = "${var.project_name}-rodc-vnic"
    hostname_label   = "${var.project_name}-rodc"
  }

  # Local Administrator password is left to OCI's default auto-generated
  # mechanism (retrieved via `oci compute instance get-windows-initial-creds`)
  # rather than embedding a password in tfvars/state -- this box only needs
  # that credential once, to do the initial WinRM connection and domain-join;
  # AD credentials take over after that. user_data only enables WinRM itself.
  metadata = {
    user_data = base64encode(local.rodc_user_data)
  }

  freeform_tags = {
    project = var.project_name
    role    = "ad-rodc"
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

output "rodc_private_ip" {
  description = "Private IP of the OCI RODC VM"
  value       = oci_core_instance.rodc.private_ip
}

output "rodc_instance_id" {
  description = "OCID of the OCI RODC VM, for instance-credentials/bastion lookups"
  value       = oci_core_instance.rodc.id
}
