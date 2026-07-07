# ── OCI Auth ──────────────────────────────────────────────────────────────────
variable "tenancy_ocid"     { description = "OCI tenancy OCID" }
variable "user_ocid"        { description = "OCI user OCID" }
variable "fingerprint"      { description = "API key fingerprint" }
variable "private_key_path"    { description = "Path to OCI API private key PEM file" }
variable "private_key_content" {
  default     = ""
  description = "OCI API private key PEM content (unused — provider uses private_key_path)"
}
variable "region" {
  description = "OCI region (e.g. eu-paris-1)"
  default     = "eu-paris-1"
}
variable "compartment_id" { description = "Compartment OCID where all resources are created" }

# ── Networking ────────────────────────────────────────────────────────────────
variable "vcn_cidr"            { default = "10.0.0.0/16" }
variable "public_subnet_cidr"  { default = "10.0.1.0/24" }
variable "private_subnet_cidr" { default = "10.0.2.0/24" }

# ── On-prem ───────────────────────────────────────────────────────────────────
variable "onprem_cidr" {
  default     = "192.168.1.0/24"
  description = "On-prem LAN CIDR"
}
variable "onprem_nlb_vip" {
  default     = "192.168.1.100"
  description = "On-prem NLB VIP (BikoDC1+BikoDC)"
}

# ── Meraki MX68 site (separate LAN, same public IP/site as on-prem) ───────────
variable "mx68_public_ip" {
  default     = "81.130.238.41"
  description = "Public IP of the site hosting the Meraki MX68 (same as onprem_public_ip -- same building/internet connection)"
}
variable "mx68_lan_cidr" {
  default     = "192.168.128.0/24"
  description = "LAN behind the Meraki MX68 (separate from onprem_cidr)"
}
variable "mx68_vpn_shared_secret" {
  default     = ""
  sensitive   = true
  description = "Pre-shared key for the MX68 <-> OCI IPSec connection"
}
variable "onprem_public_ip" { description = "Public IP of on-prem router/firewall for IPSec CPE" }
variable "onprem_api_port" {
  default     = 443
  description = "Port the on-prem NLB listens on"
}

# ── VPN ───────────────────────────────────────────────────────────────────────
variable "vpn_shared_secret" {
  description = "IPSec pre-shared key (generate with: openssl rand -base64 32)"
  sensitive   = true
}
variable "cpe_vendor" {
  default     = "Microsoft"
  description = "CPE device vendor for OCI config generation"
}

# ── Compute (hot standby) ─────────────────────────────────────────────────────
variable "availability_domain" {
  default     = ""
  description = "OCI availability domain name (e.g. Kopi:UK-LONDON-1-AD-1) — leave empty to auto-discover"
}
variable "standby_shape"      { default = "VM.Standard.E4.Flex" }
variable "standby_ocpus"      { default = 1 }
variable "standby_memory_gb"  { default = 8 }
variable "standby_image_id" {
  default     = ""
  description = "Ubuntu 22.04 image OCID — leave empty to auto-discover"
}
variable "ssh_public_key"     { description = "SSH public key to access the standby VM" }
variable "standby_private_ip" { default = "10.0.2.10" }

# ── Load Balancer ─────────────────────────────────────────────────────────────
variable "lb_min_bandwidth_mbps" { default = 10 }
variable "lb_max_bandwidth_mbps" { default = 100 }
variable "lb_cert_id" {
  default     = ""
  description = "OCI Certificate OCID for api.tekeche.com (leave empty to use self-signed bootstrap cert)"
}

# ── DNS ───────────────────────────────────────────────────────────────────────
variable "dns_zone_name" { default = "tekeche.com" }
variable "api_hostname"  { default = "api" }
variable "dns_ttl"       { default = 30 }

# ── App ───────────────────────────────────────────────────────────────────────
variable "github_repo_url" { default = "https://github.com/livbiko/tekeche-api" }
variable "github_pat" {
  default     = ""
  sensitive   = true
  description = "GitHub fine-grained PAT (read-only, scoped to tekeche-api) for cloning the private repo during standby cloud-init. Leave empty for public repos."
}
variable "app_env_secret_id" {
  default     = ""
  description = "OCI Vault secret OCID containing the .env file content"
}
variable "mongodb_rs_name" { default = "rs0" }
variable "mongodb_keyfile_content" {
  default     = ""
  sensitive   = true
  description = "Shared MongoDB replica-set keyFile content -- must be byte-identical to the on-prem keyfile (C:\\Program Files\\MongoDB\\Server\\8.3\\keyfile.txt)"
}
variable "project_name"    { default = "tekeche" }
