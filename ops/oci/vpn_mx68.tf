# ── MX68 ↔ OCI site-to-site VPN — DECOMMISSIONED 2026-07-08 ───────────────────
# Resources (oci_core_cpe.mx68, oci_core_ipsec.mx68) destroyed via targeted
# `terraform destroy`. This tunnel never got past IKE (ESP never established)
# across ~3 days of troubleshooting and an open, unresolved Meraki TAC case.
# User decided to abandon this approach entirely rather than keep waiting on
# Meraki. Corresponding non-Meraki VPN peers also removed from the Meraki
# Dashboard (PUT thirdPartyVPNPeers with an empty peers array).
#
# Full prior definition recoverable from git history before 2026-07-08 (see
# ops/MAINTENANCE_LOG.md's "Remove MX68 <-> OCI VPN" entry), including the
# encryption_domain_config traffic-selector fix and all crypto parameters,
# if this is ever revisited.
#
# NOTE: networking.tf still has route-table and security-list rules
# referencing var.mx68_lan_cidr (192.168.128.0/24) — those are now orphaned
# (no tunnel routes that CIDR anymore) but were left in place since removing
# them wasn't explicitly requested. Revisit if fully cleaning up this
# abandoned approach.
