# Wings VMs (OpenTofu, via tofu-controller)

The Proxmox VMs that run [Calagopus Wings](https://github.com/calagopus/wings)
on VLAN 50, one per world, named after it. They are part of the Calagopus app: the
[`Terraform` object](../../kubernetes/apps/default/calagopus/wings/terraform.yaml)
next to the panel points [tofu-controller](../../kubernetes/apps/flux-system/tofu-controller/README.md)
at this directory, so the VMs are changed the same way as everything else in the
cluster, by committing to Git. The migration onto them is a runbook:
[WINGS.md](../../kubernetes/apps/default/calagopus/WINGS.md).

| Wing | VMID | Node | Servers | Management | Service addresses |
| --- | --- | --- | --- | --- | --- |
| `wing-atlas` | 5031 | pve03 | Atlas | 192.168.50.39 | .30, .31, .32 |
| `wing-iridium` | 5021 | pve02 | Iridium | 192.168.50.29 | .20, .21, .22 |
| `wing-homestead` | 5011 | pve01 | Homestead | 192.168.50.19 | .10, .11, .12, .13 |
| `wing-proxy` | 5001 | pve01 | Velocity, Lobby | 192.168.50.109 | .100, .101 |

All of it is in [`main.tf`](./main.tf): the `wings` map is the inventory, and
[`templates/user-data.yaml.tftpl`](./templates/user-data.yaml.tftpl) is
everything inside the guest.

## What a wing is

- **Ubuntu 24.04 minimal cloud image** (no snapd), installed with
  `--no-install-recommends`. Docker CE, Wings, the QEMU guest agent, and
  `nfs-common` only where BlueMap is mounted.
- **Locked down by default:** key-only SSH as `ewatkins`, no root login, no
  default user. Unique SSH host keys per VM (the old wings were template
  clones that shared one set). Security updates apply daily without rebooting.
  No rpcbind listening, and no certbot or Cloudflare token on the VM: Wings
  uses a self-signed cert, which is all Envoy's TLS hop needs.
- **Serial console only**, no ballooning, no emulated display.
- **Fixed MAC** derived from the VMID (`02:00:00:00:50:31` for 5031), so a
  rebuilt wing looks like the same device to the network. Changing it
  rebuilds the VM, because the guest's network config is bound to it.
- **In the `wings` pool**, which is what the API token is limited to and what
  the `wings` backup job selects.
- **Not protected** in Proxmox: rebuilding a wing is routine. Nothing is
  destroyed without an approved plan that says so.
- **Configured once.** Cloud-init runs on first boot only (fixed
  `instance-id`). A template change reaches a wing by rebuilding it, not by
  re-running cloud-init on a live game server.

## How changes are applied

**Merging is the approval.** Open a PR; within a couple of minutes the
branch planner (tofu-controller) posts the plan for that branch as a PR
comment, planned against the real state. Read it like any other diff: it
lists every VM created, changed, replaced or **destroyed**. Merge, and the
controller applies the plan from `main` (`approvePlan: auto`). Comment
`!replan` on the PR to refresh the plan after pushing more commits.

- A plan with no changes does nothing.
- Drift is corrected hourly, **except power state and node placement**, which
  belong to Proxmox (`ignore_changes`): a wing stopped for a rollback stays
  stopped, and one moved by HA stays where it is.
- Watch an apply with `kubectl -n calagopus-wings get terraform calagopus-wings`;
  the last plan is in `kubectl -n calagopus-wings get cm tfplan-default-calagopus-wings -o jsonpath='{.data.tfplan}'`.

Everything runs in the `calagopus-wings` namespace: the `Terraform` object,
its credentials, and the state, in the Secret `tfstate-default-calagopus-wings`
(not in Git). The runner pod uses its own service account, which can reach
Secrets in that namespace only. The chart's shared `tf-runner` account can
read every Secret in the cluster, so it is not used.
Deleting the `Terraform` object leaves the VMs alone
(`destroyResourcesOnDeletion: false`).

**If the cluster is down,** running wings are unaffected (Proxmox HA keeps them
up); changes wait until the cluster is back. In an emergency, use the Proxmox
UI, then bring the code back in line before merging the next change.

## What the cluster can do on Proxmox

The cluster holds two credentials, from the Bitwarden item `tofu-wings-secret`:

| Credential | Can | Cannot |
| --- | --- | --- |
| API token `terraform@pve!tofu` | Create, configure, power and migrate VMs **in the `wings` pool**; allocate disks on `caspian-fast`; read the image on `caspian`; manage the `wings-snippets` storage; use the Minecraft VNet; **manage HA** (see below) | Configure or open a console on the Talos VMs or any VM outside the pool; other storage; node or cluster settings; the node shell; backups; users |
| SSH key for `tofu-snippets` on pve01 | Write files to the `wings-snippets` storage over SFTP | Run commands (SFTP only), forward ports, write anywhere else |

**HA** is managed here (`proxmox_haresource`). Proxmox checks `Sys.Console`
on `/` for every HA call; the token has it (with `Sys.Audit`) on `/` **only,
without propagation**. The node shell checks `Sys.Console` on
`/nodes/<node>`, which the token does not get, so this is not root on
Proxmox. It does let the token change **any** HA resource, including the
Talos VMs (stop or relocate them through HA): a compromised cluster could
disrupt itself, but not take over the hypervisor.

**Backups** stay outside: the `wings` backup job selects the pool.

## One-time setup

Run on pve01 as root unless noted.

### 1. Pool, image and backups

```sh
pvesh create /pools --poolid wings --comment "Calagopus Wings (tofu-controller)"

# The image main.tf's image_id points at.
pvesh create /nodes/pve01/storage/caspian/download-url --content import \
  --url https://cloud-images.ubuntu.com/minimal/releases/noble/release-20261008/ubuntu-24.04-minimal-cloudimg-amd64.img \
  --filename ubuntu-24.04-minimal-cloudimg-amd64-20261008.qcow2 \
  --checksum 2f119f50bf29fe40e73b69ae2a736e8210d8146796f036e0324315b6b3a777df --checksum-algorithm sha256

# Nightly, every VM in the pool.
pvesh create /cluster/backup --id wings --pool wings --schedule 18:30 --storage backups \
  --mode snapshot --fleecing enabled=1,storage=local-lvm --notification-mode notification-system \
  --notes-template '[{{vmid}}] {{guestname}}' --comment "Wings (pool)"
```

### 2. Snippets storage and its upload user

Cloud-init files live on their own storage, a subdirectory of the `proxmox`
share, mounted so that only `tofu-snippets` can write to it:

```sh
useradd --uid 2001 --user-group --create-home --shell /usr/sbin/nologin tofu-snippets
mkdir -p /mnt/pve/caspian/wings-snippets
pvesm add cifs wings-snippets --server storage.ewatkins.dev --share proxmox \
  --subdir /wings-snippets --username proxmox \
  --password "$(sed -n 's/^password=//p' /etc/pve/priv/storage/caspian.pw)" \
  --content snippets --options uid=2001,gid=2001,file_mode=0644,dir_mode=0755

cat > /etc/ssh/sshd_config.d/50-tofu-snippets.conf <<'EOF'
Match User tofu-snippets
    ForceCommand internal-sftp
    AuthenticationMethods publickey
    AllowTcpForwarding no
    X11Forwarding no
    PermitTTY no
EOF
sshd -t && systemctl reload ssh
```

On your workstation, make its key, then install the public half on pve01 as
`~tofu-snippets/.ssh/authorized_keys` (mode 0600, owned by `tofu-snippets`),
prefixed with `restrict `:

```sh
ssh-keygen -t ed25519 -N '' -C tofu-snippets -f ./tofu-snippets
```

The other nodes mount the storage too (it is shared), but only read from it.

### 3. API token

```sh
pveum role add TofuWingsVM --privs "VM.Allocate VM.Audit VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.GuestAgent.Audit VM.Migrate VM.PowerMgmt"
pveum user add terraform@pve --comment "tofu-controller: terraform/wings"
pveum acl modify /pool/wings              --users terraform@pve --roles TofuWingsVM
pveum acl modify /storage/caspian-fast    --users terraform@pve --roles PVEDatastoreUser
pveum acl modify /storage/caspian         --users terraform@pve --roles PVEAuditor
pveum acl modify /storage/wings-snippets  --users terraform@pve --roles PVEDatastoreAdmin
pveum acl modify /sdn/zones/DATA/Minecrft --users terraform@pve --roles PVESDNUser
# HA: on / itself only (--propagate 0), so not the node shell on /nodes/*.
pveum role add TofuWingsHA --privs "Sys.Audit Sys.Console"
pveum acl modify / --users terraform@pve --roles TofuWingsHA --propagate 0
pveum user token add terraform@pve tofu --privsep 0
```

Keep the token value from the last command. These are the narrowest rights I
could derive from the Proxmox and provider source; if the first plan or apply
fails with a `403` on a path, grant the missing privilege on that path only.

### 4. Bitwarden

In the `talos` Secrets Manager project, which External Secrets reads, create
`tofu-wings-secret` with this JSON value:

```json
{
  "proxmox_api_token": "terraform@pve!tofu=<token value>",
  "ssh_private_key": "<base64 -w0 of the tofu-snippets private key>"
}
```

The key is base64-encoded so it fits in one JSON string; the ExternalSecret
decodes it. Shred the private key file once it is saved.

## Day to day

- **New world:** add an entry to `wings`, named after the world (next free VMID and
  `.X9`-style management address), approve the plan, then follow WINGS.md
  from step 1.
- **More CPU, memory or disk:** change the entry and approve the plan. Disks
  only grow. `reboot_after_update` is off, so a change that needs a restart
  waits until you reboot the VM yourself.
- **Newer Ubuntu image:** download it (step 1) and bump `image_id`. Only new
  wings use it; existing ones ignore it.
- **Wings version:** `wings_version`/`wings_sha256` only set what a *new*
  wing installs. Running wings are upgraded in place (WINGS.md, "Upgrading
  Wings"), keeping them in step with the panel image.
- **Removing a wing:** set `enabled = false` and merge; its HA resource
  goes with it.
- **Local check** before pushing: `tofu init -backend=false && tofu validate`.
