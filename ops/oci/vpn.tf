# ── RRAS ↔ OCI site-to-site VPN — DECOMMISSIONED 2026-07-08 ───────────────────
# Resources (oci_core_cpe.onprem, oci_core_ipsec.onprem) destroyed via targeted
# `terraform destroy`, as step 1 of migrating on-prem<->OCI connectivity from
# RRAS to a BikoFW-SRX + MX68 SD-WAN path. Full prior definition (incl. the
# cpe_local_identifier NAT workaround) is recoverable from git history —
# see commit history for this file before 2026-07-08, or
# ops/MAINTENANCE_LOG.md's "Decommission RRAS <-> OCI VPN" entry.
#
# At time of removal, this connection was the ONLY working path from OCI to
# 192.168.1.0/24 (BIKODC, both other DCs, MongoDB/Redis replication targets).
# The MX68 <-> OCI tunnel (vpn_mx68.tf) was NOT working at removal time
# (ESP never established, open Meraki TAC case) -- so this removal leaves
# NO working on-prem<->OCI path for 192.168.1.0/24 until either MX68's
# tunnel is fixed and BikoFW-SRX routing is added for that CIDR, or this
# is restored.
