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

# ── Alert on the NLB itself being deleted ──────────────────────────────────────
# Direct response to the 2026-07-17 incident: tekeche-lb (the classic LB) was
# deleted out-of-band via the OCI Console with zero automated warning -- the
# only reason it was caught was a routine audit-log check during an unrelated
# task, hours after real users were likely already affected. Monitoring alarms
# only cover metrics, not control-plane actions like delete calls, so this
# needs the separate Events service instead.
#
# eventType strings hedge across a few plausible casing/format variants --
# empirically confirmed the audit-log equivalent for THIS exact resource is
# "com.oraclecloud.network-load-balancer-api.UpdateNetworkLoadBalancer.begin/.end"
# (verified live via a harmless tag-update + audit-log check, since neither
# OCI's Events reference docs nor a live NLB with real delete history were
# available to check the exact Events-service string directly). Delete is
# inferred by direct analogy (same PascalCase-operation-name pattern the
# classic LB's own audit trail used for its "DeleteLoadBalancer" event).
# If none of these match in practice, this alarm will simply never fire --
# it fails silently, not at apply time -- so treat this as best-effort
# hardening, not a guarantee, until an actual delete is used to confirm it.
resource "oci_events_rule" "nlb_deleted" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-nlb-deleted"
  description    = "Alert immediately if tekeche-nlb is deleted, to avoid a repeat of the 2026-07-17 undetected-outage incident."
  is_enabled     = true

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.network-load-balancer-api.DeleteNetworkLoadBalancer",
      "com.oraclecloud.network-load-balancer-api.deletenetworkloadbalancer",
      "com.oraclecloud.networkloadbalancer.deletenetworkloadbalancer",
    ]
    data = {
      resourceId = [oci_network_load_balancer_network_load_balancer.main.id]
    }
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = oci_ons_notification_topic.alerts.id
      description = "Notify on tekeche-nlb deletion"
    }
  }
}

resource "oci_monitoring_alarm" "lb_unhealthy_backend" {
  compartment_id        = var.compartment_id
  display_name          = "${var.project_name}-lb-unhealthy-backend"
  metric_compartment_id = oci_network_load_balancer_network_load_balancer.main.compartment_id
  namespace             = "oci_nlb"
  # Metric name is best-effort from OCI NLB documentation (UnHealthyBackendCount)
  # -- NOT yet verified against live emitted data, since no NLB existed in this
  # compartment to query `oci monitoring metric list` against at write time.
  # Re-check once the NLB has been running a few minutes: if this metric name
  # is wrong the alarm will just silently never fire, not error at apply time.
  query           = "UnHealthyBackendCount[1m]{resourceId = \"${oci_network_load_balancer_network_load_balancer.main.id}\"}.max() > 0"
  severity        = "WARNING"
  body            = "tekeche-nlb has at least one unhealthy backend server (on-prem NLB, standby VM, or an OKE node)."
  is_enabled      = true
  destinations    = [oci_ons_notification_topic.alerts.id]
  repeat_notification_duration = "PT1H"
}
