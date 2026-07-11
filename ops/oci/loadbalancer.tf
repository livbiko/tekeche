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
    # port = 0 means "check each backend on its own configured port" rather
    # than forcing every backend in the set to be checked on a fixed port.
    # Previously hardcoded to 443, which worked by coincidence since both
    # existing backends (onprem_nlb, standby_vm) happen to use port 443 --
    # but it silently broke health checks for the OKE node backends added
    # 2026-07-11, which listen on the ingress-nginx NodePort (30443).
    port              = 0
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

# ── Backend Set for plain HTTP — separate from the 443-only "main-backends" ───
# Previously the http-80 listener pointed at the same backend set as https-443,
# whose members are registered on port 443 -- so plain HTTP traffic (including
# ACME HTTP-01 validation and any http-to-https redirect) was being forwarded to
# each backend's port 443, hitting TLS listeners with plaintext bytes ("400 The
# plain HTTP request was sent to HTTPS port" on the Nginx standby). This set
# mirrors main-backends but targets each backend's actual port-80 listener.
resource "oci_load_balancer_backend_set" "http" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "http-backends"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_ms       = 10000
    timeout_in_millis = 5000
    retries           = 2
  }
}

resource "oci_load_balancer_backend" "onprem_nlb_http" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.http.name
  ip_address       = var.onprem_nlb_vip
  port             = 80
  weight           = 1
  drain            = false
  backup           = false
  offline          = false
}

resource "oci_load_balancer_backend" "standby_vm_http" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.http.name
  ip_address       = oci_core_instance.standby.private_ip
  port             = 80
  weight           = 1
  drain            = false
  backup           = true
  offline          = false
}

# ── Listener: TCP passthrough on 80 ───────────────────────────────────────────
# On-prem IIS returns HTTP 301 → HTTPS; no redirect rule needed at LB level.
resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http-80"
  default_backend_set_name = oci_load_balancer_backend_set.http.name
  port                     = 80
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = 60
  }
}
