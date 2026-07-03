# ── OCI Flexible Load Balancer ────────────────────────────────────────────────
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_id
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

# ── Backend Set — On-prem primary (IP_HASH for socket.io sticky sessions) ─────
resource "oci_load_balancer_backend_set" "onprem" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "onprem-backends"
  policy           = "IP_HASH"

  health_checker {
    protocol            = "HTTPS"
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
    verify_peer_certificate = false   # on-prem uses private cert; verify via health check response
  }
}

# ── Backend — On-prem NLB VIP ─────────────────────────────────────────────────
resource "oci_load_balancer_backend" "onprem_nlb" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.onprem.name
  ip_address       = var.onprem_nlb_vip
  port             = var.onprem_api_port
  weight           = 1
  drain            = false
  backup           = false
  offline          = false
}

# ── Backend Set — OCI standby (drained by default, used on failover) ──────────
resource "oci_load_balancer_backend_set" "standby" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "oci-standby"
  policy           = "IP_HASH"

  health_checker {
    protocol            = "HTTPS"
    url_path            = "/health"
    port                = 443
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 5000
    retries             = 2
    response_body_regex = ".*\"status\":\"ok\".*"
  }

  ssl_configuration {
    verify_peer_certificate = false
  }
}

resource "oci_load_balancer_backend" "standby_vm" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.standby.name
  ip_address       = oci_core_instance.standby.private_ip
  port             = 443
  weight           = 1
  drain            = true    # DRAINED — LB skips it until manually un-drained on failover
  backup           = false
  offline          = false
}

# ── SSL Certificate ────────────────────────────────────────────────────────────
# Option A: reference an OCI Certificates managed cert (preferred)
# Option B: if lb_cert_id is empty, a path rule routes HTTP → redirect
locals {
  use_managed_cert = var.lb_cert_id != ""
}

# ── Listener: HTTPS/443 ───────────────────────────────────────────────────────
resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "https-443"
  default_backend_set_name = oci_load_balancer_backend_set.onprem.name
  port                     = 443
  protocol                 = "HTTP"   # LB terminates TLS, forwards HTTP to backend

  connection_configuration {
    idle_timeout_in_seconds            = 300
    backend_tcp_proxy_protocol_version = 0
  }

  dynamic "ssl_configuration" {
    for_each = local.use_managed_cert ? [1] : []
    content {
      certificate_ids                  = [var.lb_cert_id]
      verify_peer_certificate          = false
      server_order_preference          = "ENABLED"
      protocols                        = ["TLSv1.2", "TLSv1.3"]
      cipher_suite_name                = "oci-default-ssl-cipher-suite-v1"
    }
  }

  # Route rules: failover to OCI standby when on-prem backend set is unhealthy
  rule_set_names = [oci_load_balancer_rule_set.failover.name]
}

# ── HTTP → HTTPS redirect listener ────────────────────────────────────────────
resource "oci_load_balancer_listener" "http_redirect" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http-80-redirect"
  default_backend_set_name = oci_load_balancer_backend_set.onprem.name
  port                     = 80
  protocol                 = "HTTP"

  rule_set_names = [oci_load_balancer_rule_set.http_to_https.name]
}

# ── Rule set: HTTP → HTTPS redirect ───────────────────────────────────────────
resource "oci_load_balancer_rule_set" "http_to_https" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "http-to-https"

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

# ── Rule set: failover routing ─────────────────────────────────────────────────
resource "oci_load_balancer_rule_set" "failover" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "failover-rules"

  # Forward /updates/* to on-prem (OTA bundles served from there)
  items {
    action           = "FORWARD"
    backend_set_name = oci_load_balancer_backend_set.onprem.name
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/updates"
      operator        = "PREFIX_MATCH"
    }
  }

  # All other traffic: primary on-prem, fallback OCI standby
  items {
    action           = "FORWARD"
    backend_set_name = oci_load_balancer_backend_set.onprem.name
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }
  }
}
