# ── OCI Network Load Balancer ──────────────────────────────────────────────────
# Replaces the classic flexible LB (deleted out-of-band via Console 2026-07-17,
# rebuilt as an NLB at the user's request). The classic LB was already pure TCP
# passthrough on both listeners (no SSL termination, no proxy protocol) with
# TCP-only health checks -- i.e. it was already being used exactly like an NLB.
# This is a like-for-like architecture swap, not a behavior change, except:
#   - No cookie-based session persistence (X-TEKECHE-LB) -- NLB has no L7
#     awareness. Low-impact here: only one backend is ever actively serving at
#     a time (backup=false primary / backup=true fallback), not load-spread
#     across multiple simultaneously-active backends.
#   - is_preserve_source_destination = false, matching the old listener's
#     backend_tcp_proxy_protocol_version = 0 (client IP was never conveyed to
#     backends before either).
resource "oci_network_load_balancer_network_load_balancer" "main" {
  compartment_id                 = local.pub_cid
  display_name                   = "${var.project_name}-nlb"
  subnet_id                      = oci_core_subnet.public.id
  is_private                     = false
  is_preserve_source_destination = false

  freeform_tags = {
    project = var.project_name
  }
}

# ── Backend Set — TCP passthrough, on-prem primary + OCI standby/OKE backup ────
# TLS is terminated at the backend (on-prem IIS / OCI standby Nginx).
resource "oci_network_load_balancer_backend_set" "main" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  name                     = "main-backends"
  policy                   = "FIVE_TUPLE"
  # Required for on-prem backends (192.168.1.101) reached via DRG/VPN, not LPG
  # peering -- NLB rejects "For the source preserved backendset, backend
  # ... should be in the private IP CIDR range of NLB VCN or LPG peered VCN"
  # when this defaults to true.
  is_preserve_source        = false

  health_checker {
    protocol          = "TCP"
    port              = 443
    interval_in_millis = 10000
    timeout_in_millis  = 5000
    retries            = 2
  }
}

resource "oci_network_load_balancer_backend" "onprem_nlb" {
  backend_set_name          = oci_network_load_balancer_backend_set.main.name
  network_load_balancer_id  = oci_network_load_balancer_network_load_balancer.main.id
  ip_address                = var.onprem_nlb_vip
  port                      = 443
  weight                    = 1
  is_drain                  = false
  is_backup                 = false
  is_offline                = false
}

resource "oci_network_load_balancer_backend" "standby_vm" {
  backend_set_name          = oci_network_load_balancer_backend_set.main.name
  network_load_balancer_id  = oci_network_load_balancer_network_load_balancer.main.id
  ip_address                = oci_core_instance.standby.private_ip
  port                      = 443
  weight                    = 1
  is_drain                  = false
  is_backup                 = true
  is_offline                = false
}

resource "oci_network_load_balancer_listener" "https" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  name                     = "https-443"
  default_backend_set_name = oci_network_load_balancer_backend_set.main.name
  port                     = 443
  protocol                 = "TCP"
}

# ── Backend Set for plain HTTP — separate from the 443-only "main-backends" ───
resource "oci_network_load_balancer_backend_set" "http" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  name                     = "http-backends"
  policy                   = "FIVE_TUPLE"
  is_preserve_source        = false

  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_in_millis = 10000
    timeout_in_millis  = 5000
    retries            = 2
  }
}

resource "oci_network_load_balancer_backend" "onprem_nlb_http" {
  backend_set_name          = oci_network_load_balancer_backend_set.http.name
  network_load_balancer_id  = oci_network_load_balancer_network_load_balancer.main.id
  ip_address                = var.onprem_nlb_vip
  port                      = 80
  weight                    = 1
  is_drain                  = false
  is_backup                 = false
  is_offline                = false
}

resource "oci_network_load_balancer_backend" "standby_vm_http" {
  backend_set_name          = oci_network_load_balancer_backend_set.http.name
  network_load_balancer_id  = oci_network_load_balancer_network_load_balancer.main.id
  ip_address                = oci_core_instance.standby.private_ip
  port                      = 80
  weight                    = 1
  is_drain                  = false
  is_backup                 = true
  is_offline                = false
}

resource "oci_network_load_balancer_listener" "http" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  name                     = "http-80"
  default_backend_set_name = oci_network_load_balancer_backend_set.http.name
  port                     = 80
  protocol                 = "TCP"
}
