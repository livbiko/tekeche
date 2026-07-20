# ── Livbiko Palo Alto VM-Series — isolated VCN ─────────────────────────────────
# New, fully isolated VCN for the Palo Alto integration project (see
# ops/oci HLD update + the Palo Alto integration plan artifact). Deliberately
# separate from tekeche-vcn (10.0.0.0/16) rather than a new subnet inside it --
# zero blast radius on anything currently live (SRX tunnel, LB, standby VM,
# OKE). Peered to tekeche-vcn via LPG only once the tunnel is proven (Phase 5,
# not yet done here).
#
# 3 subnets, matching Palo Alto's documented 3-interface pattern:
#   - mgmt subnet    (private) -- admin access via Bastion port-forward only,
#                                  same pattern already used for RDP/WinRM to
#                                  the Windows RODC VMs in tekeche-vcn.
#   - untrust subnet (public)  -- dataplane WAN interface, becomes the OCI-side
#                                  IPSec tunnel endpoint once the on-prem PA
#                                  exists (Phase 4, not yet done).
#   - trust subnet   (private) -- dataplane LAN interface, faces the eventual
#                                  LPG peering toward tekeche-vcn.

resource "oci_core_vcn" "livbiko_pa" {
  compartment_id = var.compartment_id
  cidr_block     = var.livbiko_pa_vcn_cidr
  display_name   = "livbiko-pa-vcn"
  dns_label      = "livbikopa"
}

resource "oci_core_internet_gateway" "livbiko_pa_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-igw"
  enabled        = true
}

# ── Route tables ────────────────────────────────────────────────────────────
resource "oci_core_route_table" "livbiko_pa_mgmt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-mgmt-rt"
  # No default route -- mgmt is reached via Bastion only, never egresses
  # directly to the internet.
}

resource "oci_core_route_table" "livbiko_pa_untrust" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-untrust-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.livbiko_pa_igw.id
  }
}

resource "oci_core_route_table" "livbiko_pa_trust" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-trust-rt"
  # Route toward tekeche-vcn added in Phase 5 once the LPG exists -- no
  # route needed yet, this subnet has nothing to reach outside itself today.
}

# ── Security lists ───────────────────────────────────────────────────────────
resource "oci_core_security_list" "livbiko_pa_mgmt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-mgmt-sl"

  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr # tekeche-vcn, where the OCI Bastion lives
    description = "HTTPS mgmt from the existing OCI Bastion only"
    tcp_options {
      max = 443
      min = 443
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr
    description = "SSH mgmt from the existing OCI Bastion only"
    tcp_options {
      max = 22
      min = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

resource "oci_core_security_list" "livbiko_pa_untrust" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-untrust-sl"

  # Scoped to the known on-prem public IP only, same source SRX/MX68 already
  # use -- not 0.0.0.0/0. Phase 3 (on-prem PA) still needs its own public IP
  # resolved before a real peer exists on the other end of this.
  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "${var.onprem_public_ip}/32"
    description = "IKE from on-prem PA (pending Phase 3)"
    udp_options {
      max = 500
      min = 500
    }
  }
  ingress_security_rules {
    protocol    = "17"
    source      = "${var.onprem_public_ip}/32"
    description = "IPSec NAT-T from on-prem PA (pending Phase 3)"
    udp_options {
      max = 4500
      min = 4500
    }
  }
  ingress_security_rules {
    protocol    = "50" # ESP
    source      = "${var.onprem_public_ip}/32"
    description = "ESP from on-prem PA (pending Phase 3)"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

resource "oci_core_security_list" "livbiko_pa_trust" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.livbiko_pa.id
  display_name   = "livbiko-pa-trust-sl"

  # Intentionally empty of cross-VCN rules until the Phase 5 LPG exists --
  # nothing outside this VCN can reach this subnet yet.
  ingress_security_rules {
    protocol    = "6"
    source      = var.livbiko_pa_vcn_cidr
    description = "Intra-VCN only, for now"
    tcp_options {
      max = 65535
      min = 1
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

# ── Subnets ──────────────────────────────────────────────────────────────────
resource "oci_core_subnet" "livbiko_pa_mgmt" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.livbiko_pa.id
  cidr_block                 = var.livbiko_pa_mgmt_subnet_cidr
  display_name               = "livbiko-pa-mgmt-subnet"
  dns_label                  = "pamgmt"
  route_table_id             = oci_core_route_table.livbiko_pa_mgmt.id
  security_list_ids          = [oci_core_security_list.livbiko_pa_mgmt.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "livbiko_pa_untrust" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.livbiko_pa.id
  cidr_block                 = var.livbiko_pa_untrust_subnet_cidr
  display_name               = "livbiko-pa-untrust-subnet"
  dns_label                  = "pauntrust"
  route_table_id             = oci_core_route_table.livbiko_pa_untrust.id
  security_list_ids          = [oci_core_security_list.livbiko_pa_untrust.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "livbiko_pa_trust" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.livbiko_pa.id
  cidr_block                 = var.livbiko_pa_trust_subnet_cidr
  display_name               = "livbiko-pa-trust-subnet"
  dns_label                  = "patrust"
  route_table_id             = oci_core_route_table.livbiko_pa_trust.id
  security_list_ids          = [oci_core_security_list.livbiko_pa_trust.id]
  prohibit_public_ip_on_vnic = true
}
