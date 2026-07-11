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

  # On-prem traffic via VPN/DRG — needed so the LB's health checks and
  # proxied traffic can reach the on-prem backend (192.168.1.0/24)
  route_rules {
    destination       = var.onprem_cidr
    network_entity_id = oci_core_drg.drg.id
  }

  # Meraki MX68 site LAN (separate from on-prem, same building/DRG)
  route_rules {
    destination       = var.mx68_lan_cidr
    network_entity_id = oci_core_drg.drg.id
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

  # Meraki MX68 site LAN (separate from on-prem, same building/DRG)
  route_rules {
    destination       = var.mx68_lan_cidr
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

  # Added for the http-backends set (ACME HTTP-01 challenge routing) -- LB
  # health checks and plain-HTTP traffic to the standby need this to avoid the
  # "plain HTTP request sent to HTTPS port" issue that port-443-only backends had.
  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    description = "HTTP from LB subnet"
    tcp_options {
      max = 80
      min = 80
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

  # Redis Sentinel gossip — OKE-hosted Sentinels (hostNetwork, on the OKE
  # nodes subnet) need to reach the standby's Sentinel, and vice versa (see
  # the matching rule on oke_nodes NSG in oke.tf).
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.4.0/24"
    description = "Redis Sentinel gossip from OKE nodes"
    tcp_options {
      max = 26379
      min = 26379
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

  # Meraki MX68 site LAN — broad reachability to the whole private subnet
  # (unscoped, unlike the narrowly-scoped on-prem rules above -- revisit if
  # the actual traffic pattern turns out to need less than "everything")
  ingress_security_rules {
    protocol    = "all"
    source      = var.mx68_lan_cidr
    description = "MX68 site LAN — full access"
  }

  # ── livbiko.local Active Directory — on-prem DCs (192.168.1.102/.103) ──────
  # reaching into OCI's private subnet. Egress back to on-prem is already
  # covered by the unrestricted "All outbound" rule below; these are only
  # needed for the reverse direction, once something AD-related runs in OCI.
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: DNS (TCP)"
    tcp_options {
      max = 53
      min = 53
    }
  }
  ingress_security_rules {
    protocol    = "17"
    source      = var.onprem_cidr
    description = "AD: DNS (UDP)"
    udp_options {
      max = 53
      min = 53
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: Kerberos (TCP)"
    tcp_options {
      max = 88
      min = 88
    }
  }
  ingress_security_rules {
    protocol    = "17"
    source      = var.onprem_cidr
    description = "AD: Kerberos (UDP)"
    udp_options {
      max = 88
      min = 88
    }
  }
  ingress_security_rules {
    protocol    = "17"
    source      = var.onprem_cidr
    description = "AD: W32Time"
    udp_options {
      max = 123
      min = 123
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: RPC Endpoint Mapper"
    tcp_options {
      max = 135
      min = 135
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: LDAP"
    tcp_options {
      max = 389
      min = 389
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: SMB"
    tcp_options {
      max = 445
      min = 445
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: LDAPS"
    tcp_options {
      max = 636
      min = 636
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: Global Catalog"
    tcp_options {
      max = 3268
      min = 3268
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: Global Catalog SSL"
    tcp_options {
      max = 3269
      min = 3269
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "AD: RPC dynamic port range"
    tcp_options {
      max = 65535
      min = 49152
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
