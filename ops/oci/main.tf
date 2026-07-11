terraform {
  # Pinned to 1.5.x: Terraform's S3 backend moved to aws-sdk-go-base v2 in
  # 1.6.0, which defaults PutObject to aws-chunked transfer encoding — OCI's
  # Object Storage S3-Compatibility API rejects this outright ("501
  # NotImplemented: AWS chunked encoding not supported"). Confirmed both
  # 1.15.8 and 1.9.8 fail identically; 1.5.7 (pre-SDKv2) works. Use
  # C:\tools\terraform-1.5.7\terraform.exe for this project until OCI adds
  # chunked-encoding support or a workaround is found upstream.
  required_version = ">= 1.5.0, < 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
  }

  # State stored in OCI Object Storage (S3-compatible API), bucket created
  # 2026-07-09 in the tekeche-pub compartment (private, versioned).
  #
  # TEMPORARILY DISABLED 2026-07-10: couldn't get a working Customer Secret Key
  # auth format for this backend this session (SignatureDoesNotMatch, then
  # AuthorizationHeaderMalformed with the namespace/username access-key format).
  # Using local state for the LB http-backend-set fix instead; state was
  # fetched from the bucket via plain `oci os object get` (not S3-compat) first
  # so local state matches remote exactly. Re-enable this block once the S3
  # auth issue is resolved, and reconcile/push state back up at that point.
  # backend "s3" {
  #   bucket   = "tekeche-tfstate"
  #   key      = "tekeche/oci.tfstate"
  #   region   = "uk-london-1"
  #   endpoint = "https://lr14abpkfrxj.compat.objectstorage.uk-london-1.oraclecloud.com"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
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
