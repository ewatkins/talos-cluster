terraform {
  required_version = ">= 1.10"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.118.1"
    }
  }

  # No backend block: tofu-controller stores the state in the Secret
  # tfstate-default-calagopus-wings in the calagopus-wings namespace, beside
  # the Terraform object (kubernetes/apps/default/calagopus/wings).
}
