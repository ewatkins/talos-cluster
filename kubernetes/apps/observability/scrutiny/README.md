# [Scrutiny](https://github.com/AnalogJ/scrutiny)

Scrutiny is the SMART disk-health dashboard for the physical machines behind
the cluster. Only the hub (web UI/API + embedded InfluxDB, `omnibus` image)
runs in Kubernetes — the Talos nodes are VMs with no real disks. SMART data
is pushed to the hub by collectors running on the machines that own drives.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://scrutiny.ewatkins.dev` | Internal gateway only |
| Image | `ghcr.io/starosdev/scrutiny` (`1.9.0-omnibus`) | Web + API + embedded InfluxDB. **Fork**, not analogj — adds MegaRAID/HBA detection and uses a different device-registration schema, so the hub and every collector must run the **same fork+version**. |
| Storage | `scrutiny-data` PVC (openebs-hostpath, 5Gi) | `/opt/scrutiny/config` + `/opt/scrutiny/influxdb` |
| API auth | None | LAN-only exposure; collectors POST unauthenticated |

## Collectors (configured outside GitOps)

Each collector runs `smartctl` locally and POSTs results to
`https://scrutiny.ewatkins.dev`. `--host-id` groups drives per machine in the UI.

### caspian (Unraid NAS)

Runs via the Unraid Docker template. Key settings:

- **Image**: `ghcr.io/starosdev/scrutiny:1.9.0-collector` — must match the hub's
  fork+version exactly, or device registration fails with a 400/500 (schema
  mismatch: `smart_support` object vs bool).
- **Privileged**: ON (or pass each `/dev/sdX` device + `SYS_RAWIO`) so
  `smartctl` can reach the drives, including MegaRAID/HBA disks.
- **Udev**: `/run/udev` mounted read-only for device-model detection.
- `COLLECTOR_API_ENDPOINT=https://scrutiny.ewatkins.dev`, `COLLECTOR_HOST_ID=caspian`.
- **`COLLECTOR_CRON_SCHEDULE`**: this fork runs its **own internal scheduler**,
  so `run` blocks and only collects on this schedule (default `0 0 * * *` =
  midnight). Set it to `0 * * * *` for hourly. To force an immediate one-off
  from the container console, clear the var for that invocation:
  `COLLECTOR_CRON_SCHEDULE= scrutiny-collector-metrics run`.

Because the caspian drives sit behind a MegaRAID/HBA, the fork auto-detects
each disk twice — once as `/dev/sdX`, once via `--device megaraid,N /dev/bus/11`
— which duplicates them in the UI. Auto-detection can't be disabled, but an
`allow_listed_devices` allow-list restricts collection to only the listed
paths. Mount a `collector.yaml` at `/opt/scrutiny/config/collector.yaml`:

```yaml
version: 1
host:
  id: caspian
allow_listed_devices:
  - /dev/sdb   # Parity
  - /dev/sdc   # Disk 4
  - /dev/sdd   # Disk 1
  - /dev/sde   # Disk 5
  - /dev/sdf   # Disk 2
  - /dev/sdg   # Disk 3
  - /dev/sdh   # Cache
  - /dev/sdi   # Cache 2
```

The megaraid `/dev/bus/11` entries don't match the allow-list, so they're
dropped and only the eight array/cache disks register.

### pve01 / pve02 / pve03 (Proxmox hosts)

Collector binary + cron on each host. Use the **starosdev fork** binary, not
AnalogJ's — the fork hub's device-registration schema differs, so an analogj
collector would fail with a 400/500. The fork tags its binary releases with the
collector's internal version (`v1.67.0`), matching the `1.9.0` hub image.

```bash
apt-get install -y smartmontools
curl -fsSL -o /usr/local/bin/scrutiny-collector-metrics \
  https://github.com/Starosdev/scrutiny/releases/download/v1.67.0/scrutiny-collector-metrics-linux-amd64
chmod +x /usr/local/bin/scrutiny-collector-metrics

# one-off test run (root, so smartctl can reach the disks incl. any HBA)
/usr/local/bin/scrutiny-collector-metrics run \
  --api-endpoint https://scrutiny.ewatkins.dev --host-id "$(hostname)"

# hourly via cron. COLLECTOR_CRON_SCHEDULE must stay UNSET here: with it set,
# the fork's `run` starts its own blocking scheduler instead of a one-shot,
# which would pile up under OS cron.
cat > /etc/cron.d/scrutiny <<'EOF'
0 * * * * root /usr/local/bin/scrutiny-collector-metrics run --api-endpoint https://scrutiny.ewatkins.dev --host-id "$(hostname)" >/dev/null 2>&1
EOF
```

## Links

- [starosdev fork (hub + collectors in use here)](https://github.com/Starosdev/scrutiny)
- [Upstream documentation](https://github.com/AnalogJ/scrutiny#readme)
- [Collector docs](https://github.com/AnalogJ/scrutiny/blob/master/docs/INSTALL_HUB_SPOKE.md)
