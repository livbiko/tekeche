# ── OKE (Kubernetes) foundation ───────────────────────────────────────────────
# Phase 1 of the on-prem -> OKE migration (see ops/oci/../../ops/MAINTENANCE_LOG.md
# 2026-07-09 entries and the approved migration plan). Purely additive: no
# existing resource is modified, no production traffic is routed here yet.
#
# Placed in var.compartment_id (the security-zone-constrained main compartment),
# matching the existing standby instance / private subnet precedent — private-
# only resources are fine there, they just need KMS-encrypted boot volumes
# (handled below via the existing oci_kms_key.app_key from vault.tf).

# ── Subnets (new, non-overlapping with the existing 10.0.1.0/24 / 10.0.2.0/24) ─
resource "oci_core_subnet" "oke_api_endpoint" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = "10.0.5.0/28"
  display_name               = "${var.project_name}-oke-api-endpoint-subnet"
  dns_label                  = "okeapi"
  route_table_id             = oci_core_route_table.private.id
  # OCI requires >= 1 security list per subnet (an update to [] is rejected
  # with "securityListIds must have at least 1 element", discovered 2026-07-11
  # when this subnet had drifted to referencing the VCN's default security
  # list out-of-band). Actual traffic control is via the dedicated NSGs below
  # (oke_cp / oke_nodes) per Oracle's documented OKE approach -- this just
  # attaches the VCN's default (permissive) list to satisfy the API, matching
  # what was already attached in practice.
  security_list_ids          = [oci_core_vcn.tekeche.default_security_list_id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "oke_nodes" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = "10.0.4.0/24"
  display_name               = "${var.project_name}-oke-nodes-subnet"
  dns_label                  = "okenodes"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_vcn.tekeche.default_security_list_id]
  prohibit_public_ip_on_vnic = true
}

# ── Network Security Groups ────────────────────────────────────────────────────
# Dedicated NSGs rather than reusing the shared "private" security list, per
# Oracle's documented approach for OKE — keeps cluster networking rules
# isolated from the standby VM's rules in networking.tf.

resource "oci_core_network_security_group" "oke_cp" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-oke-cp-nsg"
}

resource "oci_core_network_security_group" "oke_nodes" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-oke-nodes-nsg"
}

# Control plane <-> worker nodes (standard OKE required rules)
resource "oci_core_network_security_group_security_rule" "cp_egress_to_nodes" {
  network_security_group_id = oci_core_network_security_group.oke_cp.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "NETWORK_SECURITY_GROUP"
  destination                = oci_core_network_security_group.oke_nodes.id
  description                = "Control plane to worker nodes (kubelet, webhooks, all TCP)"
}

resource "oci_core_network_security_group_security_rule" "cp_ingress_from_nodes" {
  network_security_group_id = oci_core_network_security_group.oke_cp.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type                = "NETWORK_SECURITY_GROUP"
  source                     = oci_core_network_security_group.oke_nodes.id
  description                = "Worker nodes to control plane API (6443) and OKE (12250)"
}

resource "oci_core_network_security_group_security_rule" "cp_ingress_kubectl" {
  network_security_group_id = oci_core_network_security_group.oke_cp.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type                = "CIDR_BLOCK"
  source                     = var.vcn_cidr
  description                = "kubectl access to API endpoint from within the VCN (via Bastion)"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}


resource "oci_core_network_security_group_security_rule" "nodes_egress_to_cp" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "NETWORK_SECURITY_GROUP"
  destination                = oci_core_network_security_group.oke_cp.id
  description                = "Worker nodes to control plane"
}

resource "oci_core_network_security_group_security_rule" "nodes_ingress_from_cp" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type                = "NETWORK_SECURITY_GROUP"
  source                     = oci_core_network_security_group.oke_cp.id
  description                = "Control plane to worker nodes"
}

# Pod-to-pod (Flannel VXLAN) and node-to-node traffic within the node pool
resource "oci_core_network_security_group_security_rule" "nodes_intra_ingress" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source_type                = "NETWORK_SECURITY_GROUP"
  source                     = oci_core_network_security_group.oke_nodes.id
  description                = "Node-to-node and pod-to-pod (Flannel overlay)"
}

resource "oci_core_network_security_group_security_rule" "nodes_intra_egress" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "NETWORK_SECURITY_GROUP"
  destination                = oci_core_network_security_group.oke_nodes.id
  description                = "Node-to-node and pod-to-pod (Flannel overlay)"
}

# Outbound internet (via NAT, per the existing private route table) — image
# pulls from OCIR, OS updates, and the OKE control-plane service itself.
resource "oci_core_network_security_group_security_rule" "nodes_egress_internet" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination                = "0.0.0.0/0"
  description                = "Outbound via NAT (image pulls, OS updates, OKE service)"
}

# The existing on-prem security list already allows on-prem CIDR to reach the
# private subnet on 27017/6379 for the standby VM's replication traffic — the
# node pool needs the *reverse*: nodes reaching on-prem Mongo/Redis. That's
# already covered by the "all outbound" rule above, since the destination is
# the whole 0.0.0.0/0 CIDR (which the private route table further scopes to
# DRG for onprem_cidr specifically, and NAT for everything else).

# ── OKE Cluster (Enhanced — hourly control-plane fee, needed for native
# node-pool cycling used by the full-failover resize) ─────────────────────────
resource "oci_containerengine_cluster" "main" {
  compartment_id     = var.compartment_id
  name               = "${var.project_name}-oke"
  vcn_id             = oci_core_vcn.tekeche.id
  kubernetes_version = "v1.36.1"
  type               = "ENHANCED_CLUSTER"

  endpoint_config {
    is_public_ip_enabled = false
    subnet_id             = oci_core_subnet.oke_api_endpoint.id
    nsg_ids                = [oci_core_network_security_group.oke_cp.id]
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.public.id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled                = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }

  freeform_tags = {
    project = var.project_name
    phase   = "1-foundation"
  }
}

# ── Node Pool — 2 nodes, spread across 2 ADs for resilience ───────────────────
resource "oci_containerengine_node_pool" "main" {
  cluster_id         = oci_containerengine_cluster.main.id
  compartment_id     = var.compartment_id
  name               = "${var.project_name}-oke-nodepool"
  kubernetes_version = "v1.36.1"
  node_shape         = "VM.Standard.E4.Flex"

  node_shape_config {
    ocpus         = 4
    memory_in_gbs = 32
  }

  # Native rolling replace: launches a new (bigger) node before removing an
  # old one, respecting the tekeche-api PodDisruptionBudget (minAvailable: 1)
  # throughout -- avoids the manual cordon/drain/delete dance.
  node_pool_cycling_details {
    is_node_cycling_enabled = true
    maximum_surge           = "1"
    maximum_unavailable     = "0"
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                 = "ocid1.image.oc1.uk-london-1.aaaaaaaaq56hfh3qi7sowzascvzdze6ccnpq5rytewuzmh7h6ykfldwamtka"
    boot_volume_size_in_gbs = 50
  }

  node_config_details {
    size = 2

    placement_configs {
      availability_domain = "Kopi:UK-LONDON-1-AD-1"
      subnet_id             = oci_core_subnet.oke_nodes.id
    }
    placement_configs {
      availability_domain = "Kopi:UK-LONDON-1-AD-2"
      subnet_id             = oci_core_subnet.oke_nodes.id
    }

    nsg_ids = [oci_core_network_security_group.oke_nodes.id]

    kms_key_id = oci_kms_key.app_key.id
  }

  ssh_public_key = var.ssh_public_key

  initial_node_labels {
    key   = "project"
    value = var.project_name
  }
}
