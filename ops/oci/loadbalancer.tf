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

# ── Backend Set — single set, on-prem primary + OCI standby backup ─────────────
# OCI LB automatically routes to the backup backend only when all primary
# backends fail their health checks. No manual intervention needed for failover.
resource "oci_load_balancer_backend_set" "main" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "main-backends"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol            = "HTTP"
    url_path            = "/health"
    port                = var.onprem_api_port
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 5000
    retries             = 2
    response_body_regex = ".*\"status\":\"ok\".*"
  }

  session_persistence_configuration {
    cookie_name      = "X-TEKECHE-LB"
    disable_fallback = false
  }

  ssl_configuration {
    verify_peer_certificate = false
  }
}

# Primary backend: on-prem NLB VIP (receives all traffic when healthy)
resource "oci_load_balancer_backend" "onprem_nlb" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = var.onprem_nlb_vip
  port             = var.onprem_api_port
  weight           = 1
  drain            = false
  backup           = false
  offline          = false
}

# Backup backend: OCI standby VM (only activated when on-prem is unhealthy)
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

# ── Listener: HTTPS/443 ───────────────────────────────────────────────────────
locals {
  use_managed_cert = var.lb_cert_id != ""
}

resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "https-443"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 443
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds            = 300
    backend_tcp_proxy_protocol_version = 0
  }

  dynamic "ssl_configuration" {
    for_each = local.use_managed_cert ? [1] : []
    content {
      certificate_ids         = [var.lb_cert_id]
      verify_peer_certificate = false
      server_order_preference = "ENABLED"
      protocols               = ["TLSv1.2", "TLSv1.3"]
      cipher_suite_name       = "oci-default-ssl-cipher-suite-v1"
    }
  }

  rule_set_names = []
}

# ── HTTP → HTTPS redirect listener ────────────────────────────────────────────
resource "oci_load_balancer_listener" "http_redirect" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http-80-redirect"
  default_backend_set_name = oci_load_balancer_backend_set.main.name
  port                     = 80
  protocol                 = "HTTP"

  rule_set_names = [oci_load_balancer_rule_set.http_to_https.name]
}

# ── Rule set: HTTP → HTTPS redirect ───────────────────────────────────────────
resource "oci_load_balancer_rule_set" "http_to_https" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "http_to_https"

  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }
    redirect_uri {
      protocol = "HTTPS"
      port     = 443
    }
    response_code = 301
  }
}
