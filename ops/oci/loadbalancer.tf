# ── OCI Flexible Load Balancer ────────────────────────────────────────────────
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = local.pub_cid
  display_name   = "${var.project_name}-lb"
  shape          = "flexible"
  is_private     = false

  shape_details {
    minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
  }

  subnet_ids = [oci_core_subnet.public.id]

  freeform_tags = {
    project = var.project_name
  }
}

# ── Backend Set — TCP passthrough, on-prem primary + OCI standby backup ────────
# TLS is terminated at the backend (on-prem IIS / OCI standby Nginx).
# Health check on port 443 (TCP) — TCP connect confirms backend is reachable.
# ROUND_ROBIN required for backup backend support.
resource "oci_load_balancer_backend_set" "main" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "main-backends"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "TCP"
    port              = 443
    interval_ms       = 10000
    timeout_in_millis = 5000
    retries           = 2
  }
}

# Primary backend: on-prem NLB VIP (receives all traffic when healthy)
resource "oci_load_balancer_backend" "onprem_nlb" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = var.onprem_nlb_vip
  port             = 443
  weight           = 1
  drain            = false
  backup           = false
  offline          = false
}

# Backup backend: OCI standby VM (activated when on-prem health check fails)
resource "oci_load_balancer_backend" "standby_vm" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = oci_core_instance.standby.private_ip
  port             = 443
  weight           = 1
  drain            = false
  backup           = true
  offline          = false
}

# ── Listener: TCP passthrough on 443 ──────────────────────────────────────────
# TLS is end-to-end from client to backend; no cert management at LB level.
resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "https-443"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 443
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = 300
  }
}

# ── Listener: TCP passthrough on 80 ───────────────────────────────────────────
# On-prem IIS returns HTTP 301 → HTTPS; no redirect rule needed at LB level.
resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http-80"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 80
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = 60
  }
}
