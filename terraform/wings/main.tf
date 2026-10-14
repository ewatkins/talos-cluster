locals {
  # One VM per world, named after it (the proxy carries Velocity and the
  # Lobby). Set `enabled` to build a wing; WINGS.md covers doing that one
  # node at a time.
  #
  # address           The VM's own address. While a wing is being built beside
  #                   its old VM it is a temporary .X9; after the cutover it
  #                   is consolidated to .X0 (WINGS.md, step 11).
  # service_addresses Taken over from the old VM at cutover (.X0 for the
  #                   Envoy Backend, .X1 for the game server, spares). Empty
  #                   once consolidated: game servers then listen on .X0.
  # memory            Panel limits are 8200 MiB per game server and
  #                   2250 + 1125 MiB on the proxy; the rest is the OS,
  #                   Docker and Wings.
  # bluemap           Mount the shared BlueMap NFS export. Only servers
  #                   that render a map write to it.
  wings = {
    atlas = {
      enabled           = true
      servers           = "Atlas"
      vm_id             = 5031
      node              = "pve03"
      cores             = 4
      memory            = 12288
      disk              = 32
      address           = "192.168.50.30"
      service_addresses = []
      bluemap           = true
    }
    iridium = {
      enabled           = true
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
    homestead = {
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

  # A fixed MAC per wing, derived from its VMID: locally administered
  # (02:...), and readable (5031 -> 02:00:00:00:50:31). Rebuilding a wing
  # keeps its MAC, so the router and switch see the same device.
  mac = { for name, wing in local.enabled : name => format("02:00:00:00:%s:%s", substr(tostring(wing.vm_id), 0, 2), substr(tostring(wing.vm_id), 2, 2)) }

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
  # No tags: Proxmox checks tag changes against /vms/<id> only, ignoring
  # the pool, so tagging a new VM needs rights the pool-scoped token lacks
  # (PVE::GuestHelpers::assert_tag_permissions). The pool and the
  # description identify a wing instead.
  node_name = each.value.node
  vm_id     = each.value.vm_id
  # The API token's VM rights reach only this pool, and the PBS job that
  # backs up the wings selects it.
  pool_id = "wings"

  on_boot = true
  started = true
  # No Proxmox protection: rebuilding a wing is a normal operation. Every
  # destroy still needs an approved plan, which is the safeguard.
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

  # VLAN 50 is a 1500-MTU network, but the DATA SDN zone is 9000 and a
  # virtio NIC with no MTU set inherits it. At 9000, anything off-VLAN (the
  # NAS on VLAN 60) black-holes large packets: NFS mounts, then hangs.
  network_device {
    bridge      = "Minecrft"
    mtu         = 1500
    mac_address = local.mac[each.key]
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
    #
    # Plans apply on merge (approvePlan: auto), and drift is corrected hourly,
    # so leave power state and placement to Proxmox: a wing stopped for a
    # rollback (WINGS.md) must stay stopped, and one HA moved must stay put.
    #
    # cloud-init runs once per VM (fixed instance-id), so a changed template
    # must never touch an existing wing. The provider treats a new snippet
    # file ID as "replace the VM", which would destroy its game data; a
    # template change reaches a wing only by a deliberate rebuild.
    ignore_changes = [
      disk[0].import_from,
      started,
      node_name,
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
    ]
    # The guest's network config is bound to the MAC on first boot, so a
    # changed MAC would leave the VM with no network after its next reboot.
    # Rebuild instead.
    replace_triggered_by = [terraform_data.mac[each.key]]
  }
}

# HA, so a wing restarts elsewhere if its node dies. Managing HA needs
# Sys.Console on /; the token has it on / only, without propagation, which
# covers the HA API but not the node shell (/nodes/<node>). See README.md.
resource "proxmox_haresource" "wing" {
  for_each = local.enabled

  resource_id = "vm:${proxmox_virtual_environment_vm.wing[each.key].vm_id}"
  state       = "started"
  comment     = "wing-${each.key} (terraform/wings)"

  lifecycle {
    # WINGS.md rolls back by setting the HA state by hand; hourly drift
    # correction must not undo it.
    ignore_changes = [state]
  }
}

resource "terraform_data" "mac" {
  for_each = local.mac
  input    = each.value
}

output "wings" {
  description = "Management address of each wing."
  value       = { for name, wing in local.enabled : "wing-${name}" => wing.address }
}
