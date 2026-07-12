# ── Alerting ────────────────────────────────────────────────────────────────
# Phase 1 HA/DR discovery found zero alarms and zero log groups configured
# anywhere - the only way anyone would learn about an OCI-side outage was a
# user complaining. This covers the three most load-bearing failure modes:
# the live VPN path going down, an OKE node going down, and the LB losing a
# healthy backend.
resource "oci_ons_notification_topic" "alerts" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-alerts"
  description    = "HA/DR alerts: VPN tunnel down, OKE node down, LB backend unhealthy"
}

resource "oci_ons_subscription" "alerts_email" {
  compartment_id = var.compartment_id
  topic_id       = oci_ons_notification_topic.alerts.id
  protocol       = "EMAIL"
  endpoint       = var.alert_email
}

resource "oci_monitoring_alarm" "srx_vpn_tunnel_down" {
  compartment_id        = var.compartment_id
  display_name          = "${var.project_name}-srx-vpn-tunnel-down"
  metric_compartment_id = var.compartment_id
  namespace             = "oci_vpn"
  # Scoped to the live SRX tunnels via parentResourceId - the tenancy still
  # emits TunnelState for the abandoned MX68 connection too (see vpn_mx68.tf),
  # which would otherwise cause permanent false alarms.
  query           = "TunnelState[1m]{parentResourceId = \"${oci_core_ipsec.srx.id}\"}.mean() < 1"
  severity        = "CRITICAL"
  body            = "BikoFW-SRX <-> OCI VPN tunnel is down (TunnelState < 1). On-prem <-> OCI connectivity may be degraded or lost."
  is_enabled      = true
  destinations    = [oci_ons_notification_topic.alerts.id]
  repeat_notification_duration = "PT1H"
}

resource "oci_monitoring_alarm" "oke_node_down" {
  compartment_id        = var.compartment_id
  display_name          = "${var.project_name}-oke-node-down"
  metric_compartment_id = var.compartment_id
  namespace              = "oci_oke"
  # Counts nodes actively reporting ACTIVE condition; alarms if fewer than
  # the expected node pool size (2) are healthy. More robust than matching
  # specific "down" state strings, which aren't fully documented.
  query           = "NodeState[1m]{clusterId = \"${oci_containerengine_cluster.main.id}\", nodeCondition = \"ACTIVE\"}.count() < 2"
  severity        = "CRITICAL"
  body            = "Fewer than 2 OKE nodes report ACTIVE condition - a worker node may be down."
  is_enabled      = true
  destinations    = [oci_ons_notification_topic.alerts.id]
  repeat_notification_duration = "PT1H"
}

resource "oci_monitoring_alarm" "lb_unhealthy_backend" {
  compartment_id        = var.compartment_id
  display_name          = "${var.project_name}-lb-unhealthy-backend"
  metric_compartment_id = oci_load_balancer_load_balancer.main.compartment_id
  namespace             = "oci_lbaas"
  query           = "UnHealthyBackendServers[1m]{resourceId = \"${oci_load_balancer_load_balancer.main.id}\"}.max() > 0"
  severity        = "WARNING"
  body            = "tekeche-lb has at least one unhealthy backend server (on-prem NLB, standby VM, or an OKE node)."
  is_enabled      = true
  destinations    = [oci_ons_notification_topic.alerts.id]
  repeat_notification_duration = "PT1H"
}
