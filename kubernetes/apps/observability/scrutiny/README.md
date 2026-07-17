# [Scrutiny](https://github.com/AnalogJ/scrutiny)

Scrutiny is the SMART disk-health dashboard for the physical machines behind
the cluster. Only the hub (web UI/API + embedded InfluxDB, `omnibus` image)
runs in Kubernetes — the Talos nodes are VMs with no real disks. SMART data
is pushed to the hub by collectors running on the machines that own drives.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://scrutiny.ewatkins.dev` | Internal gateway only |
| Image | `ghcr.io/analogj/scrutiny` (`omnibus`) | Web + API + embedded InfluxDB |
| Storage | `scrutiny-data` PVC (openebs-hostpath, 5Gi) | `/opt/scrutiny/config` + `/opt/scrutiny/influxdb` |
| API auth | None | LAN-only exposure; collectors POST unauthenticated |

## Collectors (configured outside GitOps)

Each collector runs `smartctl` locally and POSTs results to
`https://scrutiny.ewatkins.dev`. `--host-id` groups drives per machine in the UI.

### caspian (Unraid NAS)

Docker container (or the Community Applications "Scrutiny" collector template):

```bash
docker run -d --name scrutiny-collector \
  --cap-add SYS_RAWIO --cap-add SYS_ADMIN \
  --volume /run/udev:/run/udev:ro \
  $(ls /dev/sd? /dev/nvme? 2>/dev/null | sed 's/^/--device=/') \
  -e COLLECTOR_API_ENDPOINT=https://scrutiny.ewatkins.dev \
  -e COLLECTOR_HOST_ID=caspian \
  -e COLLECTOR_CRON_SCHEDULE="0 * * * *" \
  ghcr.io/analogj/scrutiny:master-collector
```

`SYS_ADMIN` is only needed for NVMe devices.

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
