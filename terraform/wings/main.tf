locals {
  # One VM per game mode. Set `enabled` to build a wing; WINGS.md covers
  # doing that one node at a time.
  #
  # address           The VM's own management address. Never moves.
  # service_addresses Taken over from the old VM at cutover: the wing address
  #                   (.X0, the Envoy Backend), the game server (.X1) and
  #                   spare allocations. Applied by hand, see WINGS.md.
  # memory            Panel limits are 8200 MiB per game server and
  #                   2250 + 1125 MiB on the proxy; the rest is the OS,
  #                   Docker and Wings.
  # bluemap           Mount the shared BlueMap NFS export. Only servers
  #                   that render a map write to it.
  wings = {
    creative = {
      enabled           = false
      servers           = "Atlas"
      vm_id             = 5031
      node              = "pve03"
      cores             = 4
      memory            = 12288
      disk              = 32
      address           = "192.168.50.39"
      service_addresses = ["192.168.50.30", "192.168.50.31", "192.168.50.32"]
      bluemap           = true
    }
    skyblock = {
      enabled           = false
      servers           = "Iridium"
      vm_id             = 5021
      node              = "pve02"
      cores             = 4
      memory            = 12288
      disk              = 32
      address           = "192.168.50.29"
      service_addresses = ["192.168.50.20", "192.168.50.21", "192.168.50.22"]
      bluemap           = false
    }
    survival = {
      enabled           = false
      servers           = "Homestead"
      vm_id             = 5011
      node              = "pve01"
      cores             = 4
      memory            = 12288
      disk              = 64
      address           = "192.168.50.19"
      service_addresses = ["192.168.50.10", "192.168.50.11", "192.168.50.12", "192.168.50.13"]
      bluemap           = true
    }
    proxy = {
      enabled           = false
      servers           = "Velocity, Lobby"
      vm_id             = 5001
      node              = "pve01"
      cores             = 2
      memory            = 6144
      disk              = 16
      address           = "192.168.50.109"
      service_addresses = ["192.168.50.100", "192.168.50.101"]
      bluemap           = false
    }
  }

  enabled = { for name, wing in local.wings : name => wing if wing.enabled }

  gateway = "192.168.50.1"
  ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLUii06o9M7IuYRamEe5tB5GlOlB3zJu7ydmz99gHUc Personal SSH Key"

  # Keep in step with the panel image in
  # kubernetes/apps/default/calagopus/app/helmrelease.yaml.
  wings_version = "release-1.2.5"
  wings_sha256  = "2840795639a9ea06a2253469256b0b30ec0072d6242a22f0611296cb6f829e24"

  # Ubuntu's minimal cloud image (no snapd, a fraction of the standard
  # image's packages), downloaded once to shared storage by hand: fetching
  # it from here would need Sys.Modify on a node. See README.md.
  image_id = "caspian:import/ubuntu-24.04-minimal-cloudimg-amd64-20261008.qcow2"
}

# A fixed instance-id: cloud-init runs once per VM and never again, even if
# the template below changes. Template changes reach a wing by rebuilding it.
resource "proxmox_virtual_environment_file" "meta_data" {
  for_each = local.enabled

  node_name    = "pve01"
  datastore_id = "wings-snippets"
  content_type = "snippets"
  upload_mode  = "sftp"

  source_raw {
    file_name = "wing-${each.key}-meta-data.yaml"
    data      = <<-EOF
      instance-id: wing-${each.key}
      local-hostname: wing-${each.key}
    EOF
  }
}

resource "proxmox_virtual_environment_file" "user_data" {
  for_each = local.enabled

  node_name    = "pve01"
  datastore_id = "wings-snippets"
  content_type = "snippets"
  upload_mode  = "sftp"

  source_raw {
    file_name = "wing-${each.key}-user-data.yaml"
    data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
      hostname          = "wing-${each.key}"
      ssh_key           = local.ssh_key
      service_addresses = each.value.service_addresses
      bluemap           = each.value.bluemap
      wings_version     = local.wings_version
      wings_sha256      = local.wings_sha256
    })
  }
}

resource "proxmox_virtual_environment_vm" "wing" {
  for_each = local.enabled

  name        = "wing-${each.key}"
  description = "Calagopus Wings for ${each.value.servers}. Managed by tofu-controller from terraform/wings."
  tags        = ["tofu", "vlan50", "wings"]
  node_name   = each.value.node
  vm_id       = each.value.vm_id
  # The API token's VM rights reach only this pool, and the PBS job that
  # backs up the wings selects it.
  pool_id = "wings"

  on_boot = true
  started = true
  # A deleted wing takes its game data with it. To remove one, add
  # `unprotect = true` to its entry and apply before disabling it.
  protection = !try(each.value.unprotect, false)
  # HA may move the VM; follow it rather than recreate it.
  migrate = true
  # Never reboot a running game server to apply a config change.
  reboot_after_update = false
  stop_on_destroy     = true

  agent {
    enabled = true
    trim    = true
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v3"
  }

  # No ballooning: Java heaps do not give memory back.
  memory {
    dedicated = each.value.memory
    floating  = 0
  }

  operating_system {
    type = "l26"
  }

  # Serial console only; no emulated display adapter.
  serial_device {}

  vga {
    type = "serial0"
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = "caspian-fast"
    interface    = "scsi0"
    import_from  = local.image_id
    file_format  = "qcow2"
    size         = each.value.disk
    iothread     = true
    discard      = "on"
  }

  # VLAN 50 is a 1500-MTU network; the NIC's default of 1500 matches it.
  network_device {
    bridge = "Minecrft"
  }

  initialization {
    datastore_id = "caspian-fast"

    ip_config {
      ipv4 {
        address = "${each.value.address}/24"
        gateway = local.gateway
      }
    }

    dns {
      servers = [local.gateway]
    }

    meta_data_file_id = proxmox_virtual_environment_file.meta_data[each.key].id
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
  }

  lifecycle {
    # Bumping the image is for new wings only; it must not replace a
    # running one.
    ignore_changes = [disk[0].import_from]
  }
}

output "wings" {
  description = "Management address of each wing."
  value       = { for name, wing in local.enabled : "wing-${name}" => wing.address }
}
