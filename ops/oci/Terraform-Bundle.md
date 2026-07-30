# Tekeche — OCI Terraform Infrastructure as Code

**Repository:** github.com/livbiko/tekeche  
**Path:** ops/oci/  
**Generated:** 2026-07-03

---

## main.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }

  # Store state in OCI Object Storage once bucket is created
  # backend "s3" {
  #   bucket   = "tekeche-tfstate"
  #   key      = "tekeche/oci.tfstate"
  #   region   = var.region
  #   endpoint = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   force_path_style            = true
  # }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

```

---

## variables.tf

```hcl
# â”€â”€ OCI Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "tenancy_ocid"     { description = "OCI tenancy OCID" }
variable "user_ocid"        { description = "OCI user OCID" }
variable "fingerprint"      { description = "API key fingerprint" }
variable "private_key_path" { description = "Path to OCI API private key PEM file" }
variable "region"           { description = "OCI region (e.g. eu-paris-1)" default = "eu-paris-1" }
variable "compartment_id"   { description = "Compartment OCID where all resources are created" }

# â”€â”€ Networking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "vcn_cidr"             { default = "10.0.0.0/16" }
variable "public_subnet_cidr"   { default = "10.0.1.0/24" }
variable "private_subnet_cidr"  { default = "10.0.2.0/24" }

# â”€â”€ On-prem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "onprem_cidr"          { default = "192.168.1.0/24"  description = "On-prem LAN CIDR" }
variable "onprem_nlb_vip"       { default = "192.168.1.100"   description = "On-prem NLB VIP (BikoDC1+BikoDC)" }
variable "onprem_public_ip"     { description = "Public IP of on-prem router/firewall for IPSec CPE" }
variable "onprem_api_port"      { default = 443                description = "Port the on-prem NLB listens on" }

# â”€â”€ VPN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "vpn_shared_secret"    {
  description = "IPSec pre-shared key (generate with: openssl rand -base64 32)"
  sensitive   = true
}
variable "cpe_vendor"           { default = "Microsoft" description = "CPE device vendor for OCI config generation" }

# â”€â”€ Compute (hot standby) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "standby_shape"        { default = "VM.Standard.E4.Flex" }
variable "standby_ocpus"        { default = 1 }
variable "standby_memory_gb"    { default = 8 }
variable "standby_image_id"     { description = "Ubuntu 22.04 image OCID for your region â€” find at https://docs.oracle.com/iaas/images/" }
variable "ssh_public_key"       { description = "SSH public key to access the standby VM" }
variable "standby_private_ip"   { default = "10.0.2.10" }

# â”€â”€ Load Balancer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "lb_min_bandwidth_mbps" { default = 10 }
variable "lb_max_bandwidth_mbps" { default = 100 }
variable "lb_cert_id"            {
  default     = ""
  description = "OCI Certificate OCID for api.tekeche.com (leave empty to use self-signed bootstrap cert)"
}

# â”€â”€ DNS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "dns_zone_name"        { default = "tekeche.com" }
variable "api_hostname"         { default = "api" }
variable "dns_ttl"              { default = 30 }

# â”€â”€ App â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
variable "github_repo_url"      { default = "https://github.com/livbiko/tekeche-api" }
variable "app_env_secret_id"    {
  default     = ""
  description = "OCI Vault secret OCID containing the .env file content"
}
variable "mongodb_rs_name"      { default = "rs0" }
variable "project_name"         { default = "tekeche" }

```

---

## terraform.tfvars.example

```bash
# Copy this file to terraform.tfvars and fill in your values
# NEVER commit terraform.tfvars â€” it contains secrets

# â”€â”€ OCI Auth (from OCI Console â†’ Profile â†’ API Keys) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."
user_ocid        = "ocid1.user.oc1..aaaa..."
fingerprint      = "aa:bb:cc:dd:..."
private_key_path = "~/.oci/oci_api_key.pem"
region           = "eu-paris-1"
compartment_id   = "ocid1.compartment.oc1..aaaa..."

# â”€â”€ On-prem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
onprem_public_ip   = "41.x.x.x"      # your public IP at BikoDC
onprem_cidr        = "192.168.1.0/24"
onprem_nlb_vip     = "192.168.1.100"
onprem_api_port    = 443

# â”€â”€ VPN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Generate with: openssl rand -base64 32
vpn_shared_secret  = "CHANGE_ME_strong_random_secret"
cpe_vendor         = "Microsoft"   # Windows RRAS

# â”€â”€ Compute â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Find Ubuntu 22.04 image OCID at: https://docs.oracle.com/iaas/images/
standby_image_id   = "ocid1.image.oc1.eu-paris-1.aaaa..."
ssh_public_key     = "ssh-rsa AAAA..."

# â”€â”€ DNS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
dns_zone_name      = "tekeche.com"
api_hostname       = "api"

```

---

## networking.tf

```hcl
# â”€â”€ VCN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_vcn" "tekeche" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "${var.project_name}-vcn"
  dns_label      = var.project_name
}

# â”€â”€ Gateways â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-nat"
}

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-drg"
}

resource "oci_core_drg_attachment" "drg_vcn" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id   = oci_core_vcn.tekeche.id
    type = "VCN"
  }
  display_name = "${var.project_name}-drg-vcn-attach"
}

# â”€â”€ Route Tables â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-private-rt"

  # Outbound internet via NAT
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  # On-prem traffic via VPN/DRG
  route_rules {
    destination       = var.onprem_cidr
    network_entity_id = oci_core_drg.drg.id
  }
}

# â”€â”€ Security Lists â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-public-sl"

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "HTTPS from internet"
    tcp_options { min = 443; max = 443 }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTP redirect"
    tcp_options { min = 80; max = 80 }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.tekeche.id
  display_name   = "${var.project_name}-private-sl"

  # Allow LB to reach standby
  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    description = "From LB subnet"
    tcp_options { min = 443; max = 443 }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    description = "API port from LB"
    tcp_options { min = 5000; max = 5000 }
  }

  # Allow on-prem (via VPN) to reach MongoDB and Redis on standby
  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "MongoDB RS replication from on-prem"
    tcp_options { min = 27017; max = 27017 }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.onprem_cidr
    description = "Redis replication from on-prem"
    tcp_options { min = 6379; max = 6379 }
  }

  # SSH from VCN only (use Bastion for external access)
  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr
    description = "SSH within VCN"
    tcp_options { min = 22; max = 22 }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "All outbound"
  }
}

# â”€â”€ Subnets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.tekeche.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.project_name}-private-subnet"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  prohibit_public_ip_on_vnic = true
}

# â”€â”€ Bastion (SSH jump host) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_bastion_bastion" "main" {
  compartment_id               = var.compartment_id
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.private.id
  name                         = "${var.project_name}-bastion"
  client_cidr_block_allow_list = ["0.0.0.0/0"]  # restrict to your office IP in prod
  max_session_ttl_in_seconds   = 10800           # 3 hours
}

```

---

## vpn.tf

```hcl
# â”€â”€ Customer Premises Equipment (your on-prem router) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_cpe" "onprem" {
  compartment_id = var.compartment_id
  ip_address     = var.onprem_public_ip
  display_name   = "${var.project_name}-onprem-cpe"
  cpe_device_shape_id = data.oci_core_cpe_device_shapes.all.cpe_device_shapes[
    index(data.oci_core_cpe_device_shapes.all.cpe_device_shapes[*].cpe_device_info[0].vendor, var.cpe_vendor)
  ].cpe_device_shape_id
}

data "oci_core_cpe_device_shapes" "all" {}

# â”€â”€ IPSec Connection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_ipsec" "onprem" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.onprem.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "${var.project_name}-ipsec"

  static_routes  = [var.onprem_cidr]

  # OCI creates 2 tunnels for redundancy automatically
}

# â”€â”€ Tunnel 1 configuration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
data "oci_core_ipsec_connections" "tunnels" {
  compartment_id = var.compartment_id
  depends_on     = [oci_core_ipsec.onprem]
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel1" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].id

  routing = "STATIC"

  ike_version    = "V2"
  display_name   = "${var.project_name}-tunnel-1"

  shared_secret  = var.vpn_shared_secret

  phase_one_details {
    is_custom_phase_one_config = true
    authentication_algorithm   = "SHA2_256"
    encryption_algorithm       = "AES_256_CBC"
    diffie_hellman_group       = "GROUP14"
    lifetime_in_seconds        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config = true
    authentication_algorithm   = "HMAC_SHA2_256_128"
    encryption_algorithm       = "AES_256_GCM"
    lifetime_in_seconds        = 3600
    is_pfs_enabled             = true
    dh_group                   = "GROUP14"
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel2" {
  ipsec_id  = oci_core_ipsec.onprem.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[1].id

  routing      = "STATIC"
  ike_version  = "V2"
  display_name = "${var.project_name}-tunnel-2"
  shared_secret = var.vpn_shared_secret

  phase_one_details {
    is_custom_phase_one_config = true
    authentication_algorithm   = "SHA2_256"
    encryption_algorithm       = "AES_256_CBC"
    diffie_hellman_group       = "GROUP14"
    lifetime_in_seconds        = 28800
  }

  phase_two_details {
    is_custom_phase_two_config = true
    authentication_algorithm   = "HMAC_SHA2_256_128"
    encryption_algorithm       = "AES_256_GCM"
    lifetime_in_seconds        = 3600
    is_pfs_enabled             = true
    dh_group                   = "GROUP14"
  }
}

data "oci_core_ipsec_connection_tunnels" "main" {
  ipsec_id = oci_core_ipsec.onprem.id
}

# â”€â”€ Windows RRAS config (rendered for copy-paste) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Apply on-prem with:
#   Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination <tunnel1_ip> ...
#   Set-VpnS2SInterface  -Name "OCI-Tunnel1" -AuthenticationMethod PSKOnly -SharedSecret <secret>
#   Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination <tunnel2_ip> ...
#
# Then add static route:
#   New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1" -RouteMetric 1

```

---

## compute.tf

```hcl
# â”€â”€ Cloud-init script for the hot standby VM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
locals {
  cloud_init = <<-EOT
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # â”€â”€ System packages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    apt-get update -qq
    apt-get install -y -qq curl gnupg nginx git openssl

    # â”€â”€ Node.js 20 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    npm install -g pm2

    # â”€â”€ MongoDB 8 (replica set member, never primary) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.0.list
    apt-get update -qq && apt-get install -y mongodb-org

    cat > /etc/mongod.conf <<'MONGOCFG'
    storage:
      dbPath: /var/lib/mongodb
    net:
      port: 27017
      bindIp: 127.0.0.1,${standby_private_ip}
    replication:
      replSetName: "${rs_name}"
    security:
      authorization: enabled
    MONGOCFG

    systemctl enable mongod && systemctl start mongod

    # â”€â”€ Redis (replica of on-prem) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    apt-get install -y redis-server
    sed -i 's/^bind .*/bind 127.0.0.1 ${standby_private_ip}/' /etc/redis/redis.conf
    echo "replicaof ${onprem_nlb_vip} 6379" >> /etc/redis/redis.conf
    echo "replica-read-only yes"            >> /etc/redis/redis.conf
    systemctl enable redis-server && systemctl restart redis-server

    # â”€â”€ Clone tekeche-api â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    git clone ${github_repo} /opt/tekeche-api
    cd /opt/tekeche-api
    npm ci --omit=dev

    %{ if env_secret_id != "" }
    # Pull .env from OCI Vault
    apt-get install -y -qq python3-pip
    pip3 install -q oci-cli
    oci secrets secret-bundle get --secret-id "${env_secret_id}" \
      --query "data.\"secret-bundle-content\".content" --raw-output \
      | base64 -d > /opt/tekeche-api/.env
    %{ else }
    # Placeholder .env â€” replace with real values
    cat > /opt/tekeche-api/.env <<'ENVCFG'
    NODE_ENV=production
    PORT=5000
    MONGO_URI=mongodb://${standby_private_ip}:27017/tekeche?replicaSet=${rs_name}
    ENVCFG
    %{ endif }

    # â”€â”€ PM2 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    cd /opt/tekeche-api
    pm2 start ecosystem.config.js --env production
    pm2 save
    pm2 startup systemd -u root --hp /root | tail -1 | bash

    # â”€â”€ Nginx reverse proxy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/ssl/private/tekeche-selfsigned.key \
      -out /etc/ssl/certs/tekeche-selfsigned.crt \
      -subj "/CN=api.tekeche.com"

    cat > /etc/nginx/sites-available/tekeche <<'NGINXCFG'
    upstream api {
      server 127.0.0.1:5000;
      keepalive 32;
    }

    server {
      listen 80;
      return 301 https://$host$request_uri;
    }

    server {
      listen 443 ssl http2;
      server_name api.tekeche.com;

      ssl_certificate     /etc/ssl/certs/tekeche-selfsigned.crt;
      ssl_certificate_key /etc/ssl/private/tekeche-selfsigned.key;
      ssl_protocols       TLSv1.2 TLSv1.3;
      ssl_ciphers         HIGH:!aNULL:!MD5;

      # socket.io
      location /socket.io/ {
        proxy_pass         http://api;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_read_timeout 86400;
      }

      location / {
        proxy_pass         http://api;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_connect_timeout 10s;
        proxy_read_timeout    60s;
      }
    }
    NGINXCFG

    ln -sf /etc/nginx/sites-available/tekeche /etc/nginx/sites-enabled/tekeche
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl enable nginx && systemctl restart nginx

    echo "Tekeche standby ready" > /var/log/tekeche-init.log
  EOT

  cloud_init_rendered = templatefile("${path.module}/cloud_init.tpl", {
    standby_private_ip = var.standby_private_ip
    rs_name            = var.mongodb_rs_name
    onprem_nlb_vip     = var.onprem_nlb_vip
    github_repo        = var.github_repo_url
    env_secret_id      = var.app_env_secret_id
  })
}

# â”€â”€ Hot standby compute instance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_instance" "standby" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-standby"
  shape               = var.standby_shape

  shape_config {
    ocpus         = var.standby_ocpus
    memory_in_gbs = var.standby_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = var.standby_image_id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private.id
    private_ip             = var.standby_private_ip
    assign_public_ip       = false
    display_name           = "${var.project_name}-standby-vnic"
    hostname_label         = "${var.project_name}-standby"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }

  freeform_tags = {
    project = var.project_name
    role    = "hot-standby"
  }

  # Prevent accidental replacement of the standby
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

# â”€â”€ Boot volume backup policy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_core_volume_backup_policy_assignment" "standby_boot" {
  asset_id  = oci_core_instance.standby.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.bronze.volume_backup_policies[0].id
}

data "oci_core_volume_backup_policies" "bronze" {
  filter {
    name   = "display_name"
    values = ["Bronze"]
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

```

---

## cloud_init.tpl

```bash
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# â”€â”€ System packages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get update -qq
apt-get install -y -qq curl gnupg nginx git openssl

# â”€â”€ Node.js 20 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2

# â”€â”€ MongoDB 8 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
  | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-8.0.list
apt-get update -qq && apt-get install -y mongodb-org

cat > /etc/mongod.conf <<MONGOCFG
storage:
  dbPath: /var/lib/mongodb
net:
  port: 27017
  bindIp: 127.0.0.1,${standby_private_ip}
replication:
  replSetName: "${rs_name}"
security:
  authorization: enabled
MONGOCFG

systemctl enable mongod && systemctl start mongod

# â”€â”€ Redis (replica of on-prem) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y redis-server
sed -i 's/^bind .*/bind 127.0.0.1 ${standby_private_ip}/' /etc/redis/redis.conf
echo "replicaof ${onprem_nlb_vip} 6379" >> /etc/redis/redis.conf
echo "replica-read-only yes"            >> /etc/redis/redis.conf
systemctl enable redis-server && systemctl restart redis-server

# â”€â”€ Clone tekeche-api â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
git clone ${github_repo} /opt/tekeche-api
cd /opt/tekeche-api
npm ci --omit=dev

%{ if env_secret_id != "" ~}
# Pull .env from OCI Vault
snap install oci-cli --classic || pip3 install oci-cli
oci secrets secret-bundle get \
  --secret-id "${env_secret_id}" \
  --query "data.\"secret-bundle-content\".content" \
  --raw-output | base64 -d > /opt/tekeche-api/.env
%{ else ~}
# Placeholder .env â€” update via OCI Vault or manually
cat > /opt/tekeche-api/.env <<ENVCFG
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb://${standby_private_ip}:27017/tekeche?replicaSet=${rs_name}
# Fill in remaining vars: JWT_SECRET, BREVO_*, GOOGLE_MAPS_KEY etc.
ENVCFG
%{ endif ~}

# â”€â”€ PM2 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cd /opt/tekeche-api
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash

# â”€â”€ Nginx â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/tekeche-selfsigned.key \
  -out    /etc/ssl/certs/tekeche-selfsigned.crt \
  -subj   "/CN=api.tekeche.com"

cat > /etc/nginx/sites-available/tekeche <<'NGINXCFG'
upstream api {
  server 127.0.0.1:5000;
  keepalive 32;
}
server {
  listen 80;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl http2;
  server_name api.tekeche.com;
  ssl_certificate     /etc/ssl/certs/tekeche-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/tekeche-selfsigned.key;
  ssl_protocols       TLSv1.2 TLSv1.3;
  ssl_ciphers         HIGH:!aNULL:!MD5;

  location /socket.io/ {
    proxy_pass         http://api;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade    $http_upgrade;
    proxy_set_header   Connection "upgrade";
    proxy_set_header   Host       $host;
    proxy_read_timeout 86400;
  }
  location / {
    proxy_pass            http://api;
    proxy_http_version    1.1;
    proxy_set_header      Host              $host;
    proxy_set_header      X-Real-IP         $remote_addr;
    proxy_set_header      X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header      X-Forwarded-Proto $scheme;
    proxy_connect_timeout 10s;
    proxy_read_timeout    60s;
  }
}
NGINXCFG

ln -sf /etc/nginx/sites-available/tekeche /etc/nginx/sites-enabled/tekeche
rm -f  /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

echo "$(date -u) tekeche-standby init complete" >> /var/log/tekeche-init.log

```

---

## loadbalancer.tf

```hcl
# â”€â”€ OCI Flexible Load Balancer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-lb"
  shape          = "flexible"
  is_private     = false

  shape_details {
    minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
  }

  subnet_ids = [oci_core_subnet.public.id]

  freeform_tags = {
    project = var.project_name
  }
}

# â”€â”€ Backend Set â€” On-prem primary (IP_HASH for socket.io sticky sessions) â”€â”€â”€â”€â”€
resource "oci_load_balancer_backend_set" "onprem" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "onprem-backends"
  policy           = "IP_HASH"

  health_checker {
    protocol            = "HTTPS"
    url_path            = "/health"
    port                = var.onprem_api_port
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 5000
    retries             = 2
    response_body_regex = ".*\"status\":\"ok\".*"
  }

  session_persistence_configuration {
    cookie_name      = "X-TEKECHE-LB"
    disable_fallback = false
  }

  ssl_configuration {
    verify_peer_certificate = false   # on-prem uses private cert; verify via health check response
  }
}

# â”€â”€ Backend â€” On-prem NLB VIP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_backend" "onprem_nlb" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.onprem.name
  ip_address       = var.onprem_nlb_vip
  port             = var.onprem_api_port
  weight           = 1
  drain            = false
  backup           = false
  offline          = false
}

# â”€â”€ Backend Set â€” OCI standby (drained by default, used on failover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_backend_set" "standby" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "oci-standby"
  policy           = "IP_HASH"

  health_checker {
    protocol            = "HTTPS"
    url_path            = "/health"
    port                = 443
    return_code         = 200
    interval_ms         = 10000
    timeout_in_millis   = 5000
    retries             = 2
    response_body_regex = ".*\"status\":\"ok\".*"
  }

  ssl_configuration {
    verify_peer_certificate = false
  }
}

resource "oci_load_balancer_backend" "standby_vm" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.standby.name
  ip_address       = oci_core_instance.standby.private_ip
  port             = 443
  weight           = 1
  drain            = true    # DRAINED â€” LB skips it until manually un-drained on failover
  backup           = false
  offline          = false
}

# â”€â”€ SSL Certificate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Option A: reference an OCI Certificates managed cert (preferred)
# Option B: if lb_cert_id is empty, a path rule routes HTTP â†’ redirect
locals {
  use_managed_cert = var.lb_cert_id != ""
}

# â”€â”€ Listener: HTTPS/443 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "https-443"
  default_backend_set_name = oci_load_balancer_backend_set.onprem.name
  port                     = 443
  protocol                 = "HTTP"   # LB terminates TLS, forwards HTTP to backend

  connection_configuration {
    idle_timeout_in_seconds            = 300
    backend_tcp_proxy_protocol_version = 0
  }

  dynamic "ssl_configuration" {
    for_each = local.use_managed_cert ? [1] : []
    content {
      certificate_ids                  = [var.lb_cert_id]
      verify_peer_certificate          = false
      server_order_preference          = "ENABLED"
      protocols                        = ["TLSv1.2", "TLSv1.3"]
      cipher_suite_name                = "oci-default-ssl-cipher-suite-v1"
    }
  }

  # Route rules: failover to OCI standby when on-prem backend set is unhealthy
  rule_set_names = [oci_load_balancer_rule_set.failover.name]
}

# â”€â”€ HTTP â†’ HTTPS redirect listener â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_listener" "http_redirect" {
  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http-80-redirect"
  default_backend_set_name = oci_load_balancer_backend_set.onprem.name
  port                     = 80
  protocol                 = "HTTP"

  rule_set_names = [oci_load_balancer_rule_set.http_to_https.name]
}

# â”€â”€ Rule set: HTTP â†’ HTTPS redirect â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_rule_set" "http_to_https" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "http-to-https"

  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }
    redirect_uri {
      protocol = "HTTPS"
      port     = 443
    }
    response_code = 301
  }
}

# â”€â”€ Rule set: failover routing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_load_balancer_rule_set" "failover" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "failover-rules"

  # Forward /updates/* to on-prem (OTA bundles served from there)
  items {
    action           = "FORWARD"
    backend_set_name = oci_load_balancer_backend_set.onprem.name
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/updates"
      operator        = "PREFIX_MATCH"
    }
  }

  # All other traffic: primary on-prem, fallback OCI standby
  items {
    action           = "FORWARD"
    backend_set_name = oci_load_balancer_backend_set.onprem.name
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }
  }
}

```

---

## dns.tf

```hcl
# â”€â”€ OCI DNS Traffic Management â€” Failover steering policy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#
# Architecture:
#   api.tekeche.com â†’ OCI DNS Traffic Management
#     Primary:   OCI Flexible LB public IP  (health-checked)
#     Fallback:  (not needed â€” LB already handles on-prem vs standby routing)
#
# If OCI LB itself goes down (rare), DNS failover is a last-resort option.
# For now, the steering policy points at the single LB IP with health monitoring.

# â”€â”€ DNS Zone (import existing or create new) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_dns_zone" "tekeche" {
  compartment_id = var.compartment_id
  name           = var.dns_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = {
    project = var.project_name
  }
}

# â”€â”€ Health monitor for the OCI LB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

# â”€â”€ Traffic management steering policy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

# â”€â”€ DNS record: api.tekeche.com â†’ steering policy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_dns_steering_policy_attachment" "api" {
  steering_policy_id = oci_dns_steering_policy.failover.id
  zone_id            = oci_dns_zone.tekeche.id
  domain_name        = "${var.api_hostname}.${var.dns_zone_name}"
  display_name       = "${var.project_name}-api-attachment"
}

```

---

## vault.tf

```hcl
# â”€â”€ OCI Vault â€” secrets management for tekeche-api .env â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

resource "oci_kms_vault" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-vault"
  vault_type     = "DEFAULT"

  freeform_tags = {
    project = var.project_name
  }
}

# â”€â”€ Master Encryption Key (AES-256) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_kms_key" "app_key" {
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-app-key"
  management_endpoint = oci_kms_vault.main.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32   # 256-bit
  }

  protection_mode = "HSM"

  freeform_tags = {
    project = var.project_name
  }
}

# â”€â”€ Secret: tekeche-api .env file â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# The secret content is a base64-encoded .env file.
# Manage it outside of Terraform (rotate without re-deploying infra):
#
#   base64 -w 0 /path/to/.env > /tmp/env_b64.txt
#   oci vault secret create-base64 \
#     --compartment-id <compartment_ocid> \
#     --secret-name tekeche-api-env \
#     --vault-id <vault_ocid> \
#     --key-id <key_ocid> \
#     --secret-content-content $(cat /tmp/env_b64.txt)
#
# Then set app_env_secret_id in terraform.tfvars to the returned secret OCID.
# The cloud_init.tpl script fetches it with `oci secrets secret-bundle get`.

# â”€â”€ IAM Dynamic Group â€” lets the standby VM read secrets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_identity_dynamic_group" "standby_vm" {
  compartment_id = var.compartment_id   # must be tenancy root for identity resources
  name           = "${var.project_name}-standby-dg"
  description    = "OCI instances that run the tekeche-api standby"

  matching_rule = "ANY { instance.id = '${oci_core_instance.standby.id}' }"
}

# â”€â”€ IAM Policy â€” standby VM can read secrets from the vault â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
resource "oci_identity_policy" "standby_vault_read" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-standby-vault-policy"
  description    = "Allow standby VM to read app secrets from Vault"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.standby_vm.name} to read secret-bundles in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.standby_vm.name} to use keys in compartment id ${var.compartment_id}"
  ]
}

```

---

## outputs.tf

```hcl
# â”€â”€ Key outputs after `terraform apply` â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

output "lb_public_ip" {
  description = "OCI Load Balancer public IP â€” point api.tekeche.com DNS here (or let dns.tf manage it)"
  value       = oci_load_balancer_load_balancer.main.ip_address_details[0].ip_address
}

output "standby_private_ip" {
  description = "OCI hot-standby VM private IP (VPN reachable from on-prem)"
  value       = oci_core_instance.standby.private_ip
}

output "vpn_tunnel1_ip" {
  description = "OCI IPSec tunnel 1 IP â€” configure as VPN peer on Windows RRAS"
  value       = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].vpn_ip
}

output "vpn_tunnel2_ip" {
  description = "OCI IPSec tunnel 2 IP â€” redundant peer"
  value       = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[1].vpn_ip
}

output "bastion_id" {
  description = "OCI Bastion OCID â€” use to create SSH sessions into the private subnet"
  value       = oci_bastion_bastion.main.id
}

output "vault_management_endpoint" {
  description = "KMS management endpoint â€” needed for key operations"
  value       = oci_kms_vault.main.management_endpoint
}

output "vault_ocid" {
  description = "Vault OCID â€” needed when uploading secrets via oci-cli"
  value       = oci_kms_vault.main.id
}

output "master_key_ocid" {
  description = "AES-256 master key OCID â€” needed when creating secrets"
  value       = oci_kms_key.app_key.id
}

output "dns_zone_id" {
  description = "OCI DNS zone OCID"
  value       = oci_dns_zone.tekeche.id
}

output "health_monitor_id" {
  description = "HTTP health monitor OCID for the OCI LB"
  value       = oci_health_checks_http_monitor.lb_health.id
}

# â”€â”€ Post-apply checklist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
output "next_steps" {
  description = "Manual steps required after terraform apply"
  value       = <<-EOT

    â”€â”€ POST-APPLY CHECKLIST â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    1. VPN â€” configure Windows RRAS on-prem:
       Add-VpnS2SInterface -Name "OCI-Tunnel1" -Destination <vpn_tunnel1_ip>
       Add-VpnS2SInterface -Name "OCI-Tunnel2" -Destination <vpn_tunnel2_ip>
       (use shared secret from var.vpn_shared_secret)
       New-NetRoute -DestinationPrefix "10.0.0.0/16" -InterfaceAlias "OCI-Tunnel1"

    2. MongoDB RS â€” add OCI standby as replica member from on-prem mongosh:
       rs.add({ host: "10.0.2.10:27017", priority: 0, votes: 0 })

    3. Vault secret â€” upload tekeche-api .env:
       base64 -w 0 /path/to/.env > /tmp/env_b64.txt
       oci vault secret create-base64 \
         --compartment-id <compartment_ocid> \
         --secret-name tekeche-api-env \
         --vault-id <vault_ocid> \
         --key-id <master_key_ocid> \
         --secret-content-content $(cat /tmp/env_b64.txt)
       Then set app_env_secret_id = "<secret_ocid>" in terraform.tfvars and re-apply.

    4. DNS â€” if not using OCI DNS, point api.tekeche.com A record to lb_public_ip
       at your registrar (TTL 30s).

    5. LB cert â€” obtain cert for api.tekeche.com in OCI Certificates service,
       set lb_cert_id = "<cert_ocid>" in terraform.tfvars and re-apply.

    6. Verify:
       curl https://api.tekeche.com/health
       # expect: {"status":"ok"}

    7. Failover test:
       # Un-drain OCI standby in LB console, stop on-prem app,
       # verify /health still returns 200 from OCI standby.
       # Then re-drain standby and restart on-prem.

  EOT
}

```

---


