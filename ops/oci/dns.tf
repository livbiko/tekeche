# ── OCI DNS Traffic Management — Failover steering policy ─────────────────────
#
# Architecture:
#   api.tekeche.com → OCI DNS Traffic Management
#     Primary:   OCI Flexible LB public IP  (health-checked)
#     Fallback:  (not needed — LB already handles on-prem vs standby routing)
#
# If OCI LB itself goes down (rare), DNS failover is a last-resort option.
# For now, the steering policy points at the single LB IP with health monitoring.

# ── DNS Zone (import existing or create new) ───────────────────────────────────
resource "oci_dns_zone" "tekeche" {
  compartment_id = var.compartment_id
  name           = var.dns_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = {
    project = var.project_name
  }
}

# ── Health monitor for the OCI LB ─────────────────────────────────────────────
resource "oci_health_checks_http_monitor" "lb_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-lb-health"
  interval_in_seconds = 30
  protocol            = "HTTPS"
  targets             = [oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address]
  port                = 443
  path                = "/health"
  is_enabled          = true

  headers = {
    Accept = "application/json"
  }

  freeform_tags = {
    project = var.project_name
  }
}

# ── Traffic management steering policy ────────────────────────────────────────
resource "oci_dns_steering_policy" "failover" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-failover-policy"
  template       = "FAILOVER"
  ttl            = var.dns_ttl

  health_check_monitor_id = oci_health_checks_http_monitor.lb_health.id

  # Rule: answer with OCI LB; if unhealthy, drop to empty (NXDOMAIN-equivalent)
  rules {
    rule_type   = "FILTER"
    description = "Filter healthy endpoints only"

    cases {
      answer_data {
        answer_condition = "answer.isHealthy"
        should_keep      = true
      }
    }
    default_answer_data {
      answer_condition = "answer.isHealthy"
      should_keep      = true
    }
  }

  rules {
    rule_type   = "PRIORITY"
    description = "OCI LB is the primary endpoint"

    cases {
      answer_data {
        answer_condition = "answer.name == 'lb-primary'"
        value            = 1
      }
    }
    default_answer_data {
      answer_condition = "answer.name == 'lb-primary'"
      value            = 1
    }
  }

  rules {
    rule_type   = "LIMIT"
    description = "Return one answer only"
    default_count = 1
  }

  rules {
    rule_type   = "RETURN"
    description = "Return the selected answer"
  }

  # Answers: the OCI LB public IP
  answers {
    name        = "lb-primary"
    rtype       = "A"
    rdata       = oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address
    is_disabled = false
  }

  freeform_tags = {
    project = var.project_name
  }
}

# ── DNS record: api.tekeche.com → steering policy ─────────────────────────────
resource "oci_dns_steering_policy_attachment" "api" {
  steering_policy_id = oci_dns_steering_policy.failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "${var.api_hostname}.${var.dns_zone_name}"
  display_name       = "${var.project_name}-api-attachment"
}
