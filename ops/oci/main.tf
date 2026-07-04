terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
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
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key_path = var.private_key_path
  region       = var.region
}
