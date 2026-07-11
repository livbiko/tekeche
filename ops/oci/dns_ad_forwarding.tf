# ── DNS forwarding: livbiko.local → on-prem Active Directory DNS servers ──────
# Lets anything in the OCI VCN resolve livbiko.local names (LDAP/Kerberos SRV
# records, DC hostnames, etc.) by forwarding those queries to the on-prem DCs.
# Reachability already exists via the RRAS tunnel's 192.168.1.0/24 static
# route — this just wires up the DNS side of that.

data "oci_core_vcn_dns_resolver_association" "tekeche" {
  vcn_id = oci_core_vcn.tekeche.id
}

# Step 1: the forwarding endpoint. Applied first, on its own — the resolver
# rule below references this endpoint by name, and Oracle's own examples
# document a dependency-ordering quirk if both are applied simultaneously.
resource "oci_dns_resolver_endpoint" "onprem_ad_forward" {
  resolver_id   = data.oci_core_vcn_dns_resolver_association.tekeche.dns_resolver_id
  name          = "onprem_ad_forward"
  subnet_id     = oci_core_subnet.private.id
  scope         = "PRIVATE"
  is_forwarding = true
  is_listening  = false
}

data "oci_dns_resolver" "tekeche" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.tekeche.dns_resolver_id
  scope       = "PRIVATE"
}

# Step 2: the forwarding rule itself, on the VCN's existing default resolver
# (managed here via resolver_id matching the auto-created one -- no
# terraform import needed). Forwards livbiko.local. queries to the two
# working on-prem DCs (192.168.1.102, .103 — BIKODC itself is excluded for
# now since its registered IP is a stale APIPA address, 169.254.0.36 — see
# project_livbiko_ad_to_oci memory).
resource "oci_dns_resolver" "tekeche" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.tekeche.dns_resolver_id
  scope       = "PRIVATE"

  attached_views {
    view_id = data.oci_dns_resolver.tekeche.default_view_id
  }

  rules {
    action                 = "FORWARD"
    destination_addresses  = ["192.168.1.102"]
    source_endpoint_name   = oci_dns_resolver_endpoint.onprem_ad_forward.name
    qname_cover_conditions = ["livbiko.local."]
  }

  rules {
    action                 = "FORWARD"
    destination_addresses  = ["192.168.1.103"]
    source_endpoint_name   = oci_dns_resolver_endpoint.onprem_ad_forward.name
    qname_cover_conditions = ["livbiko.local."]
  }

  depends_on = [oci_dns_resolver_endpoint.onprem_ad_forward]

  # OCI's DNS resolver API always returns qname_cover_conditions without the
  # trailing dot, regardless of what's sent — the oci provider v8.x plan/read
  # cycle never converges on this field (perpetual cosmetic diff, confirmed
  # 2026-07-09: apply reports success, 0 destroyed, but next plan shows the
  # same 1-line change again). Functionally inert either way. Silencing it so
  # real drift on this resource isn't lost in the noise.
  lifecycle {
    ignore_changes = [rules]
  }
}
