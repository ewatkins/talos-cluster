# Wings: new VMs for Calagopus

Runbook for moving each game server off its Pterodactyl Wings VM and onto a
new [Calagopus Wings](https://github.com/calagopus/wings) VM. There is one VM
per game mode, defined in
[`terraform/wings`](../../../../terraform/wings/README.md) and built by
tofu-controller from the [`Terraform` object](./wings/terraform.yaml) beside
the panel. Run it once per
node, after the panel's final import (see [README.md](./README.md), Phase 3).

| Old VM | VMID | | New VM | VMID | Node | Servers | Management | Takes over |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `wing-node03` | 5030 | → | `wing-creative` | 5031 | pve03 | Atlas | .39 | .30 .31 .32 |
| `wing-node02` | 5020 | → | `wing-skyblock` | 5021 | pve02 | Iridium | .29 | .20 .21 .22 |
| `wing-node01` | 5010 | → | `wing-survival` | 5011 | pve01 | Homestead | .19 | .10 .11 .12 .13 |
| `wing-proxy` | 5000 | → | `wing-proxy` | 5001 | pve01 | Velocity, Lobby | .109 | .100 .101 |

All addresses are in `192.168.50.0/24`. Do the nodes in that order.
`wing-proxy` runs Velocity in front of the others, so it goes last.

## How it works

Each new VM boots on its own **management address** (`.X9`), so it can be
built and filled while the old VM is still serving. At cutover the old VM is
powered off and the new one takes over its **service addresses**: the wing
address `.X0` (the Envoy Backend), the game server `.X1`, and the spare
allocations. Because the addresses stay the same, nothing downstream changes:
not the panel allocations, Velocity's backends, the Envoy Backends or the
Gatus checks. Only the panel node's FQDN moves to the new name, which the
`wing-*` HTTPRoutes already answer to.

Game data is copied over with `rsync`, keeping numeric ownership. The new VM
creates the `pterodactyl` user with the old uid/gid (999:987), so the files
need no `chown`. The node's `config.yml` is copied too. It holds the node
token the panel imported, so the node authenticates without being paired
again.

**The old VM is never changed.** Its Wings is only stopped, and the VM is
powered off. It stays intact as the rollback path until it is deleted at the
end.

### Why VMs at all

Wings needs a Docker daemon: every game server is a Docker container it
creates over `/var/run/docker.sock`. Talos has no Docker, so running Wings
in the cluster would mean a privileged Docker-in-Docker pod. Upstream does
not support that, and it would tie the game servers to Talos upgrades
without gaining anything from Kubernetes scheduling.

## Before the first node

- [ ] The panel's final import is done (README Phase 3, steps 1 to 3).
- [ ] The `terraform/wings` one-time setup is done (pool, image, backup job,
      snippets storage and user, API token, Bitwarden item), and
      `kubectl -n calagopus-wings get terraform calagopus-wings` is `Ready` with no
      changes pending.
- [ ] **Space on `caspian-fast`**. New disks are thick, and the old VM's disk
      stays until it is deleted. With 78 GB free, `wing-creative` (32 GB) and
      `wing-skyblock` (32 GB) fit alongside their old VMs. **Delete
      `wing-node03` and `wing-node02` before building `wing-survival`**
      (64 GB). Check first with `pvesm status`.
- [ ] Your SSH key is loaded in an agent (`ssh-add ~/.ssh/personal_id_ed25519`).
      The copy runs on the new VM and reaches the old one through agent
      forwarding.

## Per-node procedure

The examples use `wing-creative`. Set these for the node you are doing:

```sh
WING=creative OLD_ID=5030 NEW_ID=5031
OLD=192.168.50.30 NEW=192.168.50.39
SERVICE="192.168.50.30 192.168.50.31 192.168.50.32"
```

### 1. Build the VM

Set `enabled = true` on the wing in `terraform/wings/main.tf`, commit and
push. Then read the plan and approve it:

```sh
kubectl -n calagopus-wings get terraform calagopus-wings     # plan ID in the message
kubectl -n calagopus-wings get cm tfplan-default-calagopus-wings -o jsonpath='{.data.tfplan}'
```

The plan must only **create** `wing-$WING` and its two snippets. Anything
else (above all a `destroy` or `replace` of another wing) means stop. Approve
it in the cluster (a committed approval never matches; see
[`terraform/wings`](../../../../terraform/wings/README.md#how-changes-are-applied)):

```sh
kubectl -n calagopus-wings patch terraform calagopus-wings --type merge \
  -p '{"spec":{"approvePlan":"<plan ID>"}}'
```

Once the VM exists, put it under HA (the token deliberately cannot):

```sh
ha-manager add vm:$NEW_ID --state started
```

Wait for cloud-init to finish, then check what it built:

```sh
ssh ewatkins@$NEW 'cloud-init status --wait --long'   # status: done, no errors
ssh ewatkins@$NEW '
  id pterodactyl                      # uid=999 gid=987
  docker info --format "{{.ServerVersion}} live-restore={{.LiveRestoreEnabled}}"
  /usr/local/bin/wings version
  systemctl is-enabled wings          # enabled (not started yet)
  findmnt /mnt/bluemap                # creative and survival only
  sudo ss -tlnpH                      # only sshd, and resolved on loopback
'
```

If cloud-init failed (for example a Wings checksum mismatch), fix the template,
then rebuild: `ha-manager remove vm:$NEW_ID`, `unprotect = true` and approve,
`enabled = false` and approve, and start again. Do not patch a half-built VM
by hand.

### 2. Copy the data while the servers run

This pre-copy moves the bulk of the data while the game server is still up,
so the final copy in step 4 is short:

```sh
ssh -A ewatkins@$NEW "sudo --preserve-env=SSH_AUTH_SOCK rsync -aHAX --numeric-ids --delete --info=progress2 \
  -e 'ssh -o StrictHostKeyChecking=accept-new' --rsync-path='sudo rsync' \
  ewatkins@$OLD:/var/lib/pterodactyl/ /var/lib/pterodactyl/"
```

### 3. Stop the node

Stop the node's servers from the Pterodactyl panel, then stop Wings on the
old VM and make sure nothing is left running:

```sh
ssh ewatkins@$OLD 'sudo systemctl disable --now wings; sudo docker ps --format "{{.Names}}\t{{.Status}}"'
```

Stop any server container still listed with `sudo docker stop <uuid>`.

### 4. Final copy

Run the step 2 command again; only what changed since then is copied. Then
copy the node config:

```sh
ssh -A ewatkins@$NEW "sudo --preserve-env=SSH_AUTH_SOCK rsync -a \
  --rsync-path='sudo rsync' ewatkins@$OLD:/etc/pterodactyl/config.yml /etc/calagopus-wings/config.yml"
```

Compare both sides. File counts and sizes must match:

```sh
for h in $OLD $NEW; do ssh ewatkins@$h 'sudo find /var/lib/pterodactyl/volumes -type f | wc -l; sudo du -s /var/lib/pterodactyl/volumes'; done
```

### 5. Power off the old VM

On any Proxmox node:

```sh
ha-manager set vm:$OLD_ID --state stopped
```

Use HA, not `qm shutdown`: HA would start a VM that was shut down any other
way. Wait for `ha-manager status` to show it `stopped`. Do not delete it.

### 6. Take over the service addresses

```sh
ssh ewatkins@$NEW "
  sudo mv /etc/netplan/60-service-addresses.yaml.cutover /etc/netplan/60-service-addresses.yaml
  sudo netplan apply
  ip -br addr show eth0
  for a in $SERVICE; do sudo arping -U -c 2 -I eth0 \$a; done
"
```

The `arping` broadcasts tell the router and the other wings that the
addresses have moved, so they don't wait for stale ARP entries to expire.

### 7. Point Wings at Calagopus and start it

Edit `/etc/calagopus-wings/config.yml` on the new VM (`sudoedit`) and change
only these lines:

```yaml
remote: https://mcpanel.ewatkins.dev
api:
  ssl:
    enabled: true
    cert: /etc/calagopus-wings/tls/cert.pem
    key: /etc/calagopus-wings/tls/key.pem
```

- The cert is the self-signed one cloud-init made. The old Let's Encrypt
  cert, certbot and its Cloudflare token are not carried over.
- Leave `docker.network` alone. Calagopus reads Pterodactyl's
  `network_mode: pterodactyl_nw` as its own `mode`. If Wings logs
  `docker.network.mode is set to the default "calagopus_nw"`, the key went
  missing; set `mode: pterodactyl_nw`, or servers fail with `network
  calagopus_nw not found`.

```sh
ssh ewatkins@$NEW 'sudo systemctl start wings && sudo journalctl -u wings -f'
```

### 8. Update the panel node

In Calagopus, open **Admin → Nodes → (node)**:

1. Set the **FQDN** to `wing-$WING.ewatkins.dev` and, optionally, rename
   the node to match.
2. Under **Configuration**, click **Verify Connection**. Both checks must
   pass:
   - **Backend to Wings**: the panel reaches the node through Envoy.
   - **Frontend to Wings**: your browser does too, which the console needs.

### 9. Verify against the Phase 0 inventory

- [ ] The node shows **online**, with the Calagopus Wings version.
- [ ] Every server on the node starts. Its console shows output and accepts
      commands.
- [ ] The **file manager** lists the files you expect.
- [ ] **SFTP** works on port 2022 with panel credentials. The host key is
      new, so your SFTP client will warn about it.
- [ ] A **test backup** completes, and the old backups are still listed.
- [ ] The node's Gatus check is green.
- [ ] On `wing-creative` and `wing-survival`: the BlueMap render reaches
      `atlas.ewatkins.dev`.
- [ ] Players can join through Velocity (for `wing-proxy`, Java and Bedrock).

Only move to the next node when every item passes. Leave the old VM powered
off, but in place, for at least a few days.

### 10. Delete the old VM

Once the new wing has been stable for a while, on any Proxmox node:

```sh
ha-manager remove vm:$OLD_ID
qm destroy $OLD_ID --purge
```

Then remove `$OLD_ID` from the hand-made **Minecraft Backups** job
(Datacenter → Backup). The new VM is in the `wings` pool, which the `wings`
job backs up.

## Rollback

Until step 10, on the affected node:

```sh
# Proxmox: hand the addresses back by powering off the new VM.
ha-manager set vm:$NEW_ID --state stopped
ha-manager set vm:$OLD_ID --state started
# Old VM, once it is up:
ssh ewatkins@$OLD 'sudo systemctl enable --now wings'
```

The node reconnects to Pterodactyl, which still holds its records until
Phase 4. Change the panel node's FQDN back to `wing-node0X.ewatkins.dev`.
**Anything the game server wrote on the new VM is not on the old one.** Copy
it back with the step 2 command in reverse first if you need it.

The new VM stays stopped. Either fix it and try the cutover again, or remove
it: `ha-manager remove vm:$NEW_ID`, then `unprotect = true` and
`enabled = false`, approving each plan.

## Upgrading Wings

Calagopus releases weekly. Upgrade the panel (via Renovate) and Wings
together, and check
[version compatibility](https://calagopus.com/docs/additional/troubleshooting#versions-and-clocks)
first. On each wing:

```sh
V=release-1.2.6   # the panel's version
curl -fL -o /tmp/wings https://github.com/calagopus/wings/releases/download/$V/wings-rs-x86_64-linux
sha256sum /tmp/wings   # compare with the digest on the release page
sudo install -m 0755 /tmp/wings /usr/local/bin/wings && sudo systemctl restart wings
```

Restarting Wings does not stop running game servers. Then update
`wings_version` and `wings_sha256` in `terraform/wings/main.tf` so that new
wings start on the same version.

## After every node is done

- **Drop the old hostnames.** Remove `wing-node01..03` from the HTTPRoutes in
  `network/external/app/minecraft.yaml`. Optionally rename the Backend and
  HTTPRoute resources to the new names.
- **Retire the hand-made backup job** once it lists no VMs.
- **Firewall VLAN 50** on the UniFi gateway: from the cluster (192.168.40.0/24),
  allow only 8080 and 2022. From everywhere else, allow only the game ports,
  plus SSH from your admin network. Docker publishes the game ports itself,
  so host firewall rules would not cover them; filter at the gateway instead.
- **Proxy the console through the panel** (optional). Setting
  `APP_ENABLE_WINGS_PROXY` in the HelmRelease sends browser traffic through
  the panel, after which the `wings` listener on 8080 and the `wing-*`
  routes can go.

## Links

- [Wings configuration](https://calagopus.com/docs/wings/configuration)
- [Updating Wings](https://calagopus.com/docs/wings/updating)
- [Migration troubleshooting](https://calagopus.com/docs/additional/migrations/pterodactyl#troubleshooting-the-import)
