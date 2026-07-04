locals {
  # Public resources (VCN, IGW, LB) go here — no security zone
  pub_cid = oci_identity_compartment.pub.id
}

# ── VCN ───────────────────────────────────────────────────────────────────────
resource "oci_core_vcn" "tekeche" {
  compartment_id = local.pub_cid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.project_name}-vcn"
  dns_label      = var.project_name
}

# ── Gateways ──────────────────────────────────────────────────────────────────
resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.pub_cid
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-nat"
}

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-drg"
}

resource "oci_core_drg_attachment" "drg_vcn" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id   = oci_core_vcn.tekeche.id
    type = "VCN"
  }
  display_name = "${var.project_name}-drg-vcn-attach"
}

# ── Route Tables ──────────────────────────────────────────────────────────────
resource "oci_core_route_table" "public" {
  compartment_id = local.pub_cid
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-private-rt"

  # Outbound internet via NAT
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  # On-prem traffic via VPN/DRG
  route_rules {
    destination       = var.onprem_cidr
    network_entity_id = oci_core_drg.drg.id
  }
}

# ── Security Lists ─────────────────────────────────────────────────────────────
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-public-sl"

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "HTTPS from internet"
    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTP redirect"
    tcp_options {
      max = 80
      min = 80
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-private-sl"

  # Allow LB to reach standby
  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    description = "From LB subnet"
    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    description = "API port from LB"
    tcp_options {
      max = 5000
      min = 5000
    }
  }

  # Allow on-prem (via VPN) to reach MongoDB and Redis on standby
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "MongoDB RS replication from on-prem"
    tcp_options {
      max = 27017
      min = 27017
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "Redis replication from on-prem"
    tcp_options {
      max = 6379
      min = 6379
    }
  }

  # SSH from VCN only (use Bastion for external access)
  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr
    description = "SSH within VCN"
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

# ── Subnets ────────────────────────────────────────────────────────────────────
resource "oci_core_subnet" "public" {
  compartment_id             = local.pub_cid
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.project_name}-private-subnet"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  prohibit_public_ip_on_vnic = true
}

# ── Bastion (SSH jump host) ────────────────────────────────────────────────────
resource "oci_bastion_bastion" "main" {
  compartment_id               = var.compartment_id
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.private.id
  name                         = "${var.project_name}-bastion"
  client_cidr_block_allow_list = ["0.0.0.0/0"]  # restrict to your office IP in prod
  max_session_ttl_in_seconds   = 10800           # 3 hours
}
