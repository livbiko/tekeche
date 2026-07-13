# ── OKE Phase 3 — allow the OCI LB (public subnet) to reach ingress-nginx's
# NodePort on the OKE worker nodes. Purely additive: the existing oke_nodes
# NSG (oke.tf) only permits control-plane and intra-node traffic today; the
# LB needs a new path in. No existing rule is modified.
resource "oci_core_network_security_group_security_rule" "oke_nodes_ingress_from_lb" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type                = "CIDR_BLOCK"
  source                     = var.public_subnet_cidr
  description                = "OCI LB (public subnet) to ingress-nginx NodePort (443 -> 30443)"

  tcp_options {
    destination_port_range {
      min = 30443
      max = 30443
    }
  }
}

# ── OKE nodes as a second backup path in main-backends, alongside the
# existing VM standby (oci_core_instance.standby). Both node IPs are added
# individually (ROUND_ROBIN policy handles fan-out across backup members)
# so a single node failure doesn't take out the whole backup path. The
# primary on-prem backend (onprem_nlb, backup=false in loadbalancer.tf) is
# untouched -- this only extends the pool the LB falls back to.
resource "oci_load_balancer_backend" "oke_node_1" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  # Node IPs are not stable across a node-pool resize/cycle -- these were
  # replaced 2026-07-13 (was 10.0.4.54) when the pool was resized to
  # 4 OCPU/32GB per node for full-failover capacity. If the pool is ever
  # cycled again, re-check `kubectl get nodes -o wide` and update here.
  ip_address       = "10.0.4.249"
  port             = 30443
  weight           = 1
  drain            = false
  backup           = true
  offline          = false
}

resource "oci_load_balancer_backend" "oke_node_2" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  # Was 10.0.4.95 -- see oke_node_1's comment above.
  ip_address       = "10.0.4.67"
  port             = 30443
  weight           = 1
  drain            = false
  backup           = true
  offline          = false
}

# ── Redis Sentinel gossip — standby's Sentinel reaching the OKE-hosted
# Sentinels (hostNetwork DaemonSet, bound directly to each node's real IP).
# Matching ingress rule on the standby side lives in networking.tf's private
# security list.
resource "oci_core_network_security_group_security_rule" "oke_nodes_ingress_sentinel" {
  network_security_group_id = oci_core_network_security_group.oke_nodes.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type                = "CIDR_BLOCK"
  source                     = "10.0.2.0/24"
  description                = "Redis Sentinel gossip from OCI standby"

  tcp_options {
    destination_port_range {
      min = 26379
      max = 26379
    }
  }
}
