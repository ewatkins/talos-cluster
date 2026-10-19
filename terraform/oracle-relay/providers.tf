# Credentials come from the oracle-relay-secret Secret, which the Terraform
# object passes in as variables (varsFrom).
provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}
