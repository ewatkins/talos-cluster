# Credentials come from the calagopus-wings-secret Secret, which the runner
# pod gets as environment variables: PROXMOX_VE_API_TOKEN
# (terraform@pve!tofu) and PROXMOX_VE_SSH_PRIVATE_KEY (tofu-snippets).
provider "proxmox" {
  endpoint = "https://pve01.ewatkins.dev:8006/"

  # The Proxmox API cannot upload snippets, so the cloud-init files go over
  # SFTP: plain file writes, no shell, as a user that can write only to the
  # wings-snippets storage. pve01's host keys are pinned in the runner's
  # known_hosts.
  ssh {
    username = "tofu-snippets"

    node {
      name    = "pve01"
      address = "pve01.ewatkins.dev"
    }
  }
}
