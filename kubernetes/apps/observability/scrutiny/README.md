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

### pve01 / pve02 / pve03 (Proxmox hosts)

Collector binary + cron on each host:

```bash
apt-get install -y smartmontools
curl -L -o /usr/local/bin/scrutiny-collector-metrics \
  https://github.com/AnalogJ/scrutiny/releases/latest/download/scrutiny-collector-metrics-linux-amd64
chmod +x /usr/local/bin/scrutiny-collector-metrics

# one-off test run
/usr/local/bin/scrutiny-collector-metrics run \
  --api-endpoint https://scrutiny.ewatkins.dev --host-id "$(hostname)"

# hourly via cron
cat > /etc/cron.d/scrutiny <<'EOF'
0 * * * * root /usr/local/bin/scrutiny-collector-metrics run --api-endpoint https://scrutiny.ewatkins.dev --host-id "$(hostname)" >/dev/null 2>&1
EOF
```

## Links

- [Documentation](https://github.com/AnalogJ/scrutiny#readme)
- [Collector docs](https://github.com/AnalogJ/scrutiny/blob/master/docs/INSTALL_HUB_SPOKE.md)
