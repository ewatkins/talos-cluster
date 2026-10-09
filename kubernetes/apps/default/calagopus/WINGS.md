# Wings: Pterodactyl to Calagopus

Runbook for replacing Pterodactyl Wings with
[Calagopus Wings](https://github.com/calagopus/wings) on the VLAN 50 VMs.
Run it once per node, after the panel's final import (see
[README.md](./README.md), Phase 3).

| VM | VMID | Proxmox host | Wings URL | Game IP |
| --- | --- | --- | --- | --- |
| `wing-node03` | 5030 | pve03 | `wing-node03.ewatkins.dev:8080` | 192.168.50.31 |
| `wing-node02` | 5020 | pve02 | `wing-node02.ewatkins.dev:8080` | 192.168.50.21 |
| `wing-node01` | 5010 | pve01 | `wing-node01.ewatkins.dev:8080` | 192.168.50.11 |
| `wing-proxy` | 5000 | pve01 | `wing-proxy.ewatkins.dev:8080` | 192.168.50.100, .101 |

Do them in that order. `wing-proxy` runs Velocity and the lobby in front of
the others, so it goes last.

## Why the VMs stay

Calagopus Wings, like Pterodactyl's, needs a Docker daemon: every game server
is a Docker container it creates over `/var/run/docker.sock`. Talos has no
Docker, so in the cluster it would need a privileged Docker-in-Docker pod.
Upstream does not support that, and it would couple game servers to Talos
upgrades without gaining anything from Kubernetes scheduling.

Calagopus Wings is a drop-in replacement:

- It reads `/etc/pterodactyl/config.yml` when `/etc/calagopus-wings/config.yml`
  does not exist.
- Its default data paths match Pterodactyl's, so **no server data moves**.
  Everything under `/var/lib/pterodactyl` stays where it is.
- The node token in that config was imported into the panel, so the node
  authenticates without being paired again.

Nothing in the cluster changes for this. The `wing-*` Envoy routes, the
gateway's `wings` listener on 8080 and the Gatus checks all keep working
as-is.

## Per-node procedure

### 1. Snapshot the VM

Take a Proxmox snapshot or a fresh `vzdump` of the VM right before starting.
This is the rollback point for everything below.

### 2. Stop the node's servers and Wings

Stop the node's servers from the panel, then check on the VM that none are
still running. Server containers are named after the server UUID:

```sh
docker ps --format '{{.Names}}\t{{.Status}}'
systemctl stop wings
```

Stop any server container still listed with `docker stop <uuid>` before
continuing.

### 3. Keep the old binary and config

```sh
cp -a /usr/local/bin/wings /usr/local/bin/wings.pterodactyl
cp -a /etc/pterodactyl/config.yml /root/config.yml.pterodactyl
```

### 4. Install Calagopus Wings

Pin the version the panel runs (1.2.4 at the time of writing):

```sh
curl -fL https://github.com/calagopus/wings/releases/download/release-1.2.4/wings-rs-x86_64-linux \
  -o /usr/local/bin/wings.calagopus
chmod +x /usr/local/bin/wings.calagopus
/usr/local/bin/wings.calagopus version
mv /usr/local/bin/wings.calagopus /usr/local/bin/wings
```

The existing `wings.service` unit keeps working, because it runs
`/usr/local/bin/wings`. Check it is still pointed at the default config:

```sh
systemctl cat wings | grep ExecStart
```

### 5. Point the config at Calagopus

Edit `/etc/pterodactyl/config.yml` and change only these lines:

```yaml
remote: https://calagopus.ewatkins.dev
docker:
  network:
    name: pterodactyl_nw
    mode: pterodactyl_nw      # must equal `name`
```

`docker.network.mode` must match the existing network name. Otherwise
Calagopus picks up its own default, and servers fail with
`network calagopus_nw not found`.

### 6. Start Wings and watch it connect

```sh
systemctl start wings
journalctl -u wings -f
```

In the panel, open **Admin → Nodes → (node) → Configuration** and click
**Verify Connection**. Both checks must pass:

- **Backend to Wings** (the panel reaches `wing-nodeXX.ewatkins.dev:8080`)
- **Frontend to Wings** (your browser reaches it, which the console needs)

### 7. Verify against the Phase 0 inventory

- The node shows **online**, with the Calagopus Wings version.
- Every server listed for the node in the panel starts, and its console shows
  output and accepts commands.
- The **file manager** lists the files you expect, and the sizes match
  `du -sh /var/lib/pterodactyl/volumes/*` from Phase 0.
- **SFTP** works on port 2022 with panel credentials.
- A **test backup** completes, and an old Pterodactyl backup is still listed.
- The Gatus check for the node's game server goes green.

Move to the next node only when all of these pass.

## Rollback

On the affected node:

```sh
systemctl stop wings
cp -a /usr/local/bin/wings.pterodactyl /usr/local/bin/wings
cp -a /root/config.yml.pterodactyl /etc/pterodactyl/config.yml
systemctl start wings
```

The node reconnects to Pterodactyl, which still holds its records until
Phase 4. If anything on disk looks wrong, roll the VM back to the snapshot
from step 1 instead.

## After all nodes are done

These are optional and can come later:

- **Move the config.** Copy `/etc/pterodactyl/config.yml` to
  `/etc/calagopus-wings/config.yml`. Calagopus prefers that path; the old one
  works but is a fallback.
- **Proxy the console through the panel.** Setting `APP_ENABLE_WINGS_PROXY`
  in the HelmRelease sends browser traffic through the panel. After that, the
  `wings` listener on 8080 and the four `wing-*` routes in
  `network/external/app/minecraft.yaml` can go. Leave it until everything else
  is stable.
- **Keep Wings updated.** Calagopus releases weekly. Upgrade the panel (via
  Renovate) and Wings together, and check
  [version compatibility](https://calagopus.com/docs/additional/troubleshooting#versions-and-clocks)
  first.
- **Remove the old binary.** Delete `/usr/local/bin/wings.pterodactyl` and
  `/root/config.yml.pterodactyl` once Pterodactyl is decommissioned.

## Links

- [Wings configuration](https://calagopus.com/docs/wings/configuration)
- [Updating Wings](https://calagopus.com/docs/wings/updating)
- [Migration troubleshooting](https://calagopus.com/docs/additional/migrations/pterodactyl#troubleshooting-the-import)
