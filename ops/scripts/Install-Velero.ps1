# Reinstalls/reconfigures Velero for OKE cluster backup against the
# tekeche-velero-backups OCI Object Storage bucket. Not meant to run
# routinely - only if Velero needs to be reinstalled from scratch.
#
# Two non-obvious fixes baked in, both discovered the hard way on 2026-07-12:
#
# 1. This cluster's container runtime runs in "short name mode is enforcing"
#    - unqualified image refs like "velero/velero:v1.18.2" fail with
#    ImageInspectError. Every image below is fully-qualified (docker.io/...).
#
# 2. velero-plugin-for-aws v1.9.0+ migrated to AWS SDK v2, which defaults to
#    aws-chunked transfer encoding on S3 PutObject - OCI's S3-compatible API
#    rejects this with "NotImplemented: AWS chunked encoding not supported".
#    Same root cause as the OCI Terraform S3-backend issue (see
#    project_oci_terraform_version_pin memory), fixed the same way: pin to
#    the last SDK-v1-based release, v1.8.2.
#
# Prerequisites:
#   - velero.exe on PATH (or in C:\tools\velero)
#   - A Customer Secret Key for the OCI user, written to the path below as:
#       [default]
#       aws_access_key_id=<key id>
#       aws_secret_access_key=<key>
#     Generate via: oci iam customer-secret-key create --user-id <ocid> --display-name velero-backup-key
#   - kubectl context pointed at the cluster (e.g. via the bastion tunnel)

param(
    [string]$KubeContext = "tunnel-context",
    [string]$CredentialsFile = "C:\tekeche-ops\velero\credentials-velero",
    [string]$Bucket = "tekeche-velero-backups",
    [string]$Namespace = "lr14abpkfrxj",
    [string]$Region = "uk-london-1"
)

velero install `
  --kubecontext $KubeContext `
  --provider aws `
  --plugins docker.io/velero/velero-plugin-for-aws:v1.8.2 `
  --image docker.io/velero/velero:v1.18.2 `
  --bucket $Bucket `
  --prefix tekeche `
  --use-volume-snapshots=false `
  --secret-file $CredentialsFile `
  --backup-location-config "region=$Region,s3ForcePathStyle=true,s3Url=https://$Namespace.compat.objectstorage.$Region.oraclecloud.com" `
  --namespace velero `
  --wait

Write-Host "`nApplying daily backup schedule..."
kubectl --context $KubeContext apply -f "$PSScriptRoot\..\k8s\velero-schedule.yaml"
