# ── OCI DNS Traffic Management — Failover steering policy ─────────────────────
#
# Architecture:
#   api.tekeche.com → OCI DNS Traffic Management
#     Primary:   OCI Network LB public IP  (health-checked)
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
  targets             = [oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address]
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

# ── DNS record: api.tekeche.com → OCI LB public IP ────────────────────────────
# The LB backend set already handles on-prem vs OCI standby failover internally;
# a DNS steering policy would add complexity without benefit for a single LB endpoint.
resource "oci_dns_rrset" "api" {
  zone_name_or_id = oci_dns_zone.tekeche.id
  domain          = "${var.api_hostname}.${var.dns_zone_name}"
  rtype           = "A"

  items {
    domain = "${var.api_hostname}.${var.dns_zone_name}"
    rtype  = "A"
    rdata  = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    ttl    = var.dns_ttl
  }
}
