# [Homelable](https://github.com/Pouzor/homelable)

Self-hosted homelab infrastructure visualization: interactive network diagrams with live status checks, nmap-based network scanning, and Proxmox/Zigbee2MQTT/Z-Wave imports.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Backend image | `ghcr.io/pouzor/homelable-backend:3.0.0` | Runs unprivileged (PSS `baseline` forbids `NET_RAW`): nmap uses TCP-connect scans; ping works via the `net.ipv4.ping_group_range` sysctl |
| Frontend image | `ghcr.io/pouzor/homelable-frontend:3.0.0` | nginx; config overridden to proxy API to localhost (same pod) |
| MCP image | `ghcr.io/pouzor/homelable-mcp:3.0.0` | Same pod; `BACKEND_URL=http://127.0.0.1:8000` |
| URL | `https://homelab.ewatkins.dev` | Internal gateway only |
| MCP URL | `https://homelab-mcp.ewatkins.dev` | Internal gateway only; clients authenticate with `MCP_API_KEY` |
| Scanner ranges | `10.40.0.0/24`, `10.40.1.0/24` | Adjust `SCANNER_RANGES` in the HelmRelease |
| Data PVC | `homelable-data`, 2Gi (`openebs-hostpath`) | SQLite DB + uploads at `/app/data`; ⚠️ Talos node upgrades wipe OpenEBS local PVs |
| Secret | Bitwarden entry `homelable-secret` | Synced via ExternalSecrets into `homelable-secret` |

## Bitwarden secret

Create a Secrets Manager entry named `homelable-secret` whose value is JSON; keys become backend env vars:

```json
{
  "SECRET_KEY": "<openssl rand -hex 32>",
  "AUTH_USERNAME": "admin",
  "AUTH_PASSWORD_HASH": "<bcrypt hash — see upstream .env.example>",
  "MCP_API_KEY": "<echo \"mcp_sk_$(openssl rand -hex 24)\">",
  "MCP_SERVICE_KEY": "<echo \"svc_$(openssl rand -hex 24)\">"
}
```

`AUTH_USERNAME`/`AUTH_PASSWORD_HASH` are **required** — the app's default password hash is empty, so every login fails until they are set (the `admin`/`admin` default only applies to docker-compose deployments, which load a hash from `.env.example`). Generate the bcrypt hash inside the backend pod:

```bash
kubectl exec -it -n default deploy/homelable -c app -- \
  python3 -c "from passlib.context import CryptContext; import getpass; print(CryptContext(schemes=['bcrypt']).hash(getpass.getpass('password: ')))"
```

After updating the Bitwarden entry, force a sync (otherwise it refreshes within 15m); Reloader restarts the pod automatically:

```bash
kubectl annotate externalsecret homelable -n default force-sync=$(date +%s) --overwrite
```

## Notes

- Backend and MCP containers both load `homelable-secret`, so `MCP_SERVICE_KEY` (MCP → backend auth) matches automatically.
- The backend scans the LAN from the pod network (SNAT to node IP); ARP-based discovery does not cross the L2 boundary, so scans rely on ICMP/TCP probes.
- If unprivileged scanning proves too limited, the alternative is labeling the namespace `pod-security.kubernetes.io/enforce: privileged` (like `media`) and restoring the `NET_RAW` capability.

## Links

- [GitHub Repository](https://github.com/Pouzor/homelable)
