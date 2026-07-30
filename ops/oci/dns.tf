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

# ── NOTE, 2026-07-18: pay/security/staging-api A, _dmarc/SPF/brevo-code TXT,
# and both brevoN._domainkey CNAMEs already exist live in this zone (added
# directly via the OCI console during the 2026-07-10 incident response) but
# are deliberately left OUT of Terraform here. `terraform import` for
# oci_dns_rrset against these specific console-created records fails with a
# provider error ("can not marshal to path... ZoneNameOrId... nil pointer") --
# reproduced against multiple ID formats, including the exact format that
# correctly identifies the already-Terraform-managed `api` rrset below, so
# it's a provider/data quirk specific to these records, not an ID-syntax
# mistake. None of these records are touched by this change, so leaving them
# unmanaged is zero-risk -- don't attempt to fold them into Terraform state
# without first resolving that import error.

# ═══════════════════════════════════════════════════════════════════════════
# ── 2026-07-18: DNS-layer FAILOVER for tekeche.com + livbiko.com ────────────
#
# Tonight's real BikoDC power-off test caused a total blackout of both sites
# for external users -- their public DNS pointed straight at the on-prem IP
# with zero failover. api.tekeche.com already survives this via the OCI NLB's
# own backend-set failover (see above); this section gives tekeche.com/
# livbiko.com equivalent protection, but at the DNS layer itself, so a total
# on-prem internet/firewall outage (not just a single-server failure) is also
# covered -- layered on top of, not replacing, the NLB's existing mechanism.
#
# Rule order matters and is NOT arbitrary: OCI's Traffic Management requires
# FILTER -> HEALTH -> PRIORITY -> LIMIT for a FAILOVER-style policy. The
# steering policy this repo had once before (removed in commit 1a17660) tried
# to hand-roll health-based filtering into the FILTER rule's answer_condition
# ("answer.isHealthy" as a bare string) -- that's exactly backwards. Health
# filtering is its own separate HEALTH rule_type, driven automatically by
# health_check_monitor_id; FILTER only ever handles answer.isDisabled.
# ═══════════════════════════════════════════════════════════════════════════

# ── livbiko.com — separate registrar zone from tekeche.com, own delegation.
# Live Microsoft 365 email today (p=reject DMARC -- strict, a dropped record
# bounces real mail, not just degrades). Every record below mirrors what's
# live at register.com exactly (verified 2026-07-18 via public DNS).
resource "oci_dns_zone" "livbiko" {
  compartment_id = var.compartment_id
  name           = var.livbiko_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_rrset" "livbiko_mx" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = var.livbiko_zone_name
  rtype           = "MX"
  items {
    domain = var.livbiko_zone_name
    rtype  = "MX"
    rdata  = "0 livbiko-com.mail.protection.outlook.com."
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "livbiko_txt" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = var.livbiko_zone_name
  rtype           = "TXT"
  items {
    domain = var.livbiko_zone_name
    rtype  = "TXT"
    rdata  = "\"v=spf1 include:spf.protection.outlook.com -all\""
    ttl    = 3600
  }
  items {
    domain = var.livbiko_zone_name
    rtype  = "TXT"
    rdata  = "\"MS=ms29250416\""
    ttl    = 3600
  }
  items {
    domain = var.livbiko_zone_name
    rtype  = "TXT"
    rdata  = "\"_mwuonajfids21pndth5ho8qbcesf6x8\""
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "livbiko_dmarc" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = "_dmarc.${var.livbiko_zone_name}"
  rtype           = "TXT"
  items {
    domain = "_dmarc.${var.livbiko_zone_name}"
    rtype  = "TXT"
    rdata  = "\"v=DMARC1; p=reject; pct=100\""
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "livbiko_dkim_1" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = "selector1._domainkey.${var.livbiko_zone_name}"
  rtype           = "CNAME"
  items {
    domain = "selector1._domainkey.${var.livbiko_zone_name}"
    rtype  = "CNAME"
    rdata  = "selector1-livbiko-com._domainkey.livbiko.k-v1.dkim.mail.microsoft."
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "livbiko_dkim_2" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = "selector2._domainkey.${var.livbiko_zone_name}"
  rtype           = "CNAME"
  items {
    domain = "selector2._domainkey.${var.livbiko_zone_name}"
    rtype  = "CNAME"
    rdata  = "selector2-livbiko-com._domainkey.livbiko.k-v1.dkim.mail.microsoft."
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "livbiko_autodiscover" {
  zone_name_or_id = oci_dns_zone.livbiko.id
  domain          = "autodiscover.${var.livbiko_zone_name}"
  rtype           = "CNAME"
  items {
    domain = "autodiscover.${var.livbiko_zone_name}"
    rtype  = "CNAME"
    rdata  = "autodiscover.outlook.com."
    ttl    = 3600
  }
}

# ── Health checks — one per hostname, HTTP+Host header (not HTTPS+SNI) so we
# don't have to prove OCI Health Checks' HTTPS monitor sends a hostname-
# specific ClientHello against a bare IP target. IIS's host-header dispatch
# is universal at the HTTP layer, so this is sufficient and unambiguous.
# Independent per-hostname checks (not one shared check) -- if tekeche.com's
# IIS site breaks specifically, only it fails over, not livbiko.com too.
resource "oci_health_checks_http_monitor" "tekeche_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-tekeche-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/"
  is_enabled          = true
  headers = {
    Host = var.dns_zone_name
  }
  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_health_checks_http_monitor" "livbiko_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-livbiko-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/"
  is_enabled          = true
  headers = {
    Host = var.livbiko_zone_name
  }
  freeform_tags = {
    project = var.project_name
  }
}

# ── FAILOVER steering policies — primary = on-prem IP direct, backup = OCI
# NLB IP (which is itself already HA across BikoDC/standby/OKE at the
# backend-set level -- this is a second, independent layer above that one).
resource "oci_dns_steering_policy" "tekeche_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-tekeche-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.tekeche_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy" "livbiko_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-livbiko-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.livbiko_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

# ── Attachments. tekeche.com/www.tekeche.com: the OCI zone still has live
# static A rrsets for these two names today (added out-of-band, see NOTE
# above) -- those must be deleted via direct OCI CLI BEFORE this apply, since
# a steering-policy attachment can't coexist with a static rrset of the same
# name+type and Terraform doesn't manage those specific records. This is
# zero production risk either way: register.com remains authoritative until
# the separate, explicitly-approved Phase 3 registrar cutover, so nothing
# public ever resolves via this zone until then.
resource "oci_dns_steering_policy_attachment" "tekeche_apex" {
  steering_policy_id = oci_dns_steering_policy.tekeche_failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = var.dns_zone_name
}

resource "oci_dns_steering_policy_attachment" "tekeche_www" {
  steering_policy_id = oci_dns_steering_policy.tekeche_failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "www.${var.dns_zone_name}"
}

resource "oci_dns_steering_policy_attachment" "livbiko_apex" {
  steering_policy_id = oci_dns_steering_policy.livbiko_failover.id
  zone_id            = oci_dns_zone.livbiko.id
  domain_name        = var.livbiko_zone_name
}

resource "oci_dns_steering_policy_attachment" "livbiko_www" {
  steering_policy_id = oci_dns_steering_policy.livbiko_failover.id
  zone_id            = oci_dns_zone.livbiko.id
  domain_name        = "www.${var.livbiko_zone_name}"
}

# ═══════════════════════════════════════════════════════════════════════════
# ── 2026-07-19: DNS-layer FAILOVER for kendebabi.com ────────────────────────
#
# Extends the same pattern to kendebabi.com. Unlike tekeche.com/livbiko.com,
# this is a self-contained PHP+MySQL app (no separate API), so real MySQL
# replication (BikoDC -> standby, see ops/MAINTENANCE_LOG.md 2026-07-19) and
# a PHP-FPM+nginx setup on the standby (10.0.2.10) were needed before this
# DNS layer meant anything -- both done and verified same session. Every
# record below mirrors what's live at register.com exactly (verified via
# public DNS 2026-07-19). Mail here is best-effort forwarding
# (inbound.registeredsite.com), no DMARC -- lower stakes than livbiko.com's
# strict-DMARC M365 email.
# ═══════════════════════════════════════════════════════════════════════════

resource "oci_dns_zone" "kendebabi" {
  compartment_id = var.compartment_id
  name           = var.kendebabi_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_rrset" "kendebabi_mx" {
  zone_name_or_id = oci_dns_zone.kendebabi.id
  domain          = var.kendebabi_zone_name
  rtype           = "MX"
  items {
    domain = var.kendebabi_zone_name
    rtype  = "MX"
    rdata  = "10 inbound.registeredsite.com."
    ttl    = 3600
  }
}

resource "oci_dns_rrset" "kendebabi_txt" {
  zone_name_or_id = oci_dns_zone.kendebabi.id
  domain          = var.kendebabi_zone_name
  rtype           = "TXT"
  items {
    domain = var.kendebabi_zone_name
    rtype  = "TXT"
    rdata  = "\"brevo-code:5c35bafe9c0e1d809352079e54a4a554\""
    ttl    = 3600
  }
  items {
    domain = var.kendebabi_zone_name
    rtype  = "TXT"
    rdata  = "\"v=spf1 include:_spf.emfwd.name-services.com mx ?all\""
    ttl    = 3600
  }
  items {
    domain = var.kendebabi_zone_name
    rtype  = "TXT"
    rdata  = "\"google-site-verification=atF-yrEuCoHXNLFxtohR6odsnRwmQA29Ud4rAP8ab8M\""
    ttl    = 3600
  }
}

resource "oci_health_checks_http_monitor" "kendebabi_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-kendebabi-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/"
  is_enabled          = true
  headers = {
    Host = var.kendebabi_zone_name
  }
  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy" "kendebabi_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-kendebabi-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.kendebabi_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy_attachment" "kendebabi_apex" {
  steering_policy_id = oci_dns_steering_policy.kendebabi_failover.id
  zone_id            = oci_dns_zone.kendebabi.id
  domain_name        = var.kendebabi_zone_name
}

resource "oci_dns_steering_policy_attachment" "kendebabi_www" {
  steering_policy_id = oci_dns_steering_policy.kendebabi_failover.id
  zone_id            = oci_dns_zone.kendebabi.id
  domain_name        = "www.${var.kendebabi_zone_name}"
}

# ═══════════════════════════════════════════════════════════════════════════
# ── 2026-07-19: DNS-layer FAILOVER for security.tekeche.com ────────────────
#
# security.tekeche.com is NOT a separate app -- it's served by the same
# tekeche-api process as api.tekeche.com, at the /security/* route (see
# proxy-security-tekeche's web.config, IIS ARR rewrite). The standby
# already runs the identical tekeche-api process, so this only needed a new
# nginx server block there (rewrite -> /security/*, proxying to the same
# 127.0.0.1:5000 the standby's own api.tekeche.com block already uses) plus
# copying security.tekeche.com's own dedicated cert -- no new backend
# process, no MySQL/data layer involved. Verified end-to-end via the real
# NLB path (drain on-prem, confirm 302->./login from the standby, restore)
# before touching this zone.
#
# pay.tekeche.com and staging-api.tekeche.com deliberately NOT extended:
# pay has no backend process running at all right now (incomplete payment
# integration, see project_payment_gateway_dr_gap memory) and staging-api
# is a non-production test environment -- neither warrants this investment
# today. Revisit pay.tekeche.com once its backend actually exists.
#
# Unlike tekeche.com/livbiko.com/kendebabi.com, tekeche.com's zone is
# ALREADY live/authoritative (cut over 2026-07-18) -- this isn't a
# zero-risk pre-cutover build, it's a live change to a production zone.
# ═══════════════════════════════════════════════════════════════════════════

# security.tekeche.com already has a live, unmanaged static A record in this
# zone (added out-of-band, same category as the tekeche.com/www.tekeche.com
# ones noted above) -- deleted via direct OCI CLI immediately before this
# apply so the steering-policy attachment can take its place with no gap.

resource "oci_health_checks_http_monitor" "security_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-security-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/"
  is_enabled          = true
  headers = {
    Host = "security.${var.dns_zone_name}"
  }
  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy" "security_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-security-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.security_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy_attachment" "security_apex" {
  steering_policy_id = oci_dns_steering_policy.security_failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "security.${var.dns_zone_name}"
}

# ═══════════════════════════════════════════════════════════════════════════
# ── 2026-07-19: DNS-layer FAILOVER for staging-api.tekeche.com ─────────────
#
# staging-api.tekeche.com is a real, independently-running tekeche-api
# process (ecosystem.config.js's "staging" app: APP_ENV=staging, PORT=5001)
# connected to its own isolated MongoDB Atlas cluster
# (cluster0.gb0orks.mongodb.net/tekeche-staging) -- NOT the on-prem rs0
# replica set, so unlike kendebabi.com this needed zero data replication.
# Deployed the identical codebase (already present on the standby for
# production) as a second PM2 process there, its own nginx server block +
# dedicated cert. Verified end-to-end via the real NLB path (drain on-prem,
# confirm real {"env":"staging"} health response from the standby, restore).
# ═══════════════════════════════════════════════════════════════════════════

resource "oci_health_checks_http_monitor" "staging_api_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-staging-api-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/health"
  is_enabled          = true
  headers = {
    Host = "staging-api.${var.dns_zone_name}"
  }
  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy" "staging_api_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-staging-api-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.staging_api_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy_attachment" "staging_api_apex" {
  steering_policy_id = oci_dns_steering_policy.staging_api_failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "staging-api.${var.dns_zone_name}"
}

# ═══════════════════════════════════════════════════════════════════════════
# ── 2026-07-19: DNS SCAFFOLDING (only) for pay.tekeche.com ──────────────────
#
# pay.tekeche.com has NO backend process running at all right now -- the
# Wave Checkout payment gateway integration was never completed (credentials
# never obtained, see project_payment_gateway_dr_gap memory). Explicit user
# decision: build the DNS scaffolding now so it's ready whenever the
# payment gateway goes live, but do NOT attempt a functional failover test
# -- there's nothing real on either side to validate (on-prem itself
# already 502s). The health monitor below will report "onprem" unhealthy
# indefinitely until a real backend exists on port 5002; that's expected,
# not a bug. No standby-side work (no nginx block, no process) was done
# for this one -- purely the OCI DNS layer.
# ═══════════════════════════════════════════════════════════════════════════

resource "oci_health_checks_http_monitor" "pay_onprem_health" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-pay-onprem-health"
  interval_in_seconds = 30
  protocol            = "HTTP"
  targets             = [var.mx68_public_ip]
  port                = 80
  path                = "/"
  is_enabled          = true
  headers = {
    Host = "pay.${var.dns_zone_name}"
  }
  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy" "pay_failover" {
  compartment_id          = var.compartment_id
  display_name            = "${var.project_name}-pay-failover"
  template                = "FAILOVER"
  health_check_monitor_id = oci_health_checks_http_monitor.pay_onprem_health.id
  ttl                     = var.dns_ttl

  answers {
    name  = "onprem"
    rtype = "A"
    rdata = var.mx68_public_ip
    pool  = "onprem"
  }
  answers {
    name  = "oci-nlb"
    rtype = "A"
    rdata = oci_network_load_balancer_network_load_balancer.main.ip_addresses[0].ip_address
    pool  = "oci-nlb"
  }

  rules {
    rule_type = "FILTER"
    default_answer_data {
      answer_condition = "answer.isDisabled != true"
      should_keep      = true
    }
  }

  rules {
    rule_type = "HEALTH"
  }

  rules {
    rule_type = "PRIORITY"
    default_answer_data {
      answer_condition = "answer.pool == 'onprem'"
      value            = 1
    }
    default_answer_data {
      answer_condition = "answer.pool == 'oci-nlb'"
      value            = 99
    }
  }

  rules {
    rule_type     = "LIMIT"
    default_count = 1
  }

  freeform_tags = {
    project = var.project_name
  }
}

resource "oci_dns_steering_policy_attachment" "pay_apex" {
  steering_policy_id = oci_dns_steering_policy.pay_failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "pay.${var.dns_zone_name}"
}
