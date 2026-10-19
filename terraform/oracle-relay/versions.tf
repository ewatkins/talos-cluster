terraform {
  required_version = ">= 1.10"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "9.8.0"
    }
  }

  # No backend block: tofu-controller stores the state in the Secret
  # tfstate-default-oracle-relay in the oracle-relay namespace, beside the
  # Terraform object (kubernetes/apps/network/minecraft-relay/terraform).
}
