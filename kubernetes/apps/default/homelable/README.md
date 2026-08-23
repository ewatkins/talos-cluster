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
| Scanner ranges | `192.168.95.0/24` | UI-managed, persisted to `scan_config.json` on the PVC; **not** in the HelmRelease (see Notes) |
| Proxmox import | `pve01.ewatkins.dev:8006`, auto-sync hourly | Reads the whole PVE cluster; token `homelable@pve!homelable` |
| Homepage widget | `/api/v1/stats/summary` | Enabled by `HOMEPAGE_API_KEY`; consumed by the gethomepage `customapi` widget |
| Data PVC | `homelable-data`, 2Gi (`openebs-hostpath`) | SQLite DB + uploads at `/app/data`; ⚠️ Talos node upgrades wipe OpenEBS local PVs |
| Auth | OIDC via Keycloak (`AUTH_MODE=oidc`) | Client `homelable` on the `master` realm; replaces local username/password login |
| Secret | Bitwarden entry `homelable-secret` | Synced via ExternalSecrets into `homelable-secret` |

## Bitwarden secret

Create a Secrets Manager entry named `homelable-secret` whose value is JSON; keys become backend env vars:

```json
{
  "SECRET_KEY": "<openssl rand -hex 32>",
  "OIDC_CLIENT_SECRET": "<from the Keycloak client's Credentials tab>",
  "PROXMOX_TOKEN_SECRET": "<shown once when the PVE API token is created>",
  "HOMEPAGE_API_KEY": "<openssl rand -hex 24>",
  "MCP_API_KEY": "<echo \"mcp_sk_$(openssl rand -hex 24)\">",
  "MCP_SERVICE_KEY": "<echo \"svc_$(openssl rand -hex 24)\">"
}
```

`SECRET_KEY` must be at least 32 bytes in OIDC mode — it signs the session JWT. The backend refuses to start otherwise.

`AUTH_USERNAME`/`AUTH_PASSWORD_HASH` are no longer used: OIDC mode is exclusive, so the local login form is gone entirely. They can stay in the Bitwarden entry as a fallback for reverting (see below) or be removed.

After updating the Bitwarden entry, force a sync (otherwise it refreshes within 15m); Reloader restarts the pod automatically:

```bash
kubectl annotate externalsecret homelable -n default force-sync=$(date +%s) --overwrite
```

## OIDC (Keycloak)

Login is delegated to [Keycloak](../../security/keycloak/README.md) using the Authorization Code flow with PKCE. The backend validates the ID token against the realm JWKS and mints its own `__Host-`, `HttpOnly`, `Secure` session cookie (8h default); provider tokens never reach the browser.

| Setting | Value |
| --- | --- |
| Discovery URL | `https://keycloak.ewatkins.dev/realms/master/.well-known/openid-configuration` |
| Client ID | `homelable` |
| Redirect URI | `https://homelab.ewatkins.dev/api/v1/auth/oidc/callback` |
| Scopes | `openid profile email` |
| Client secret | `OIDC_CLIENT_SECRET` in the `homelable-secret` Bitwarden entry |

### Keycloak client setup

In the `master` realm: **Clients → Create client → OpenID Connect**, client ID `homelable`, **Client authentication ON** (confidential). Set **Valid redirect URIs** to the redirect URI above — it must match exactly, path included. Copy the secret from the **Credentials** tab into the Bitwarden entry.

### Unaffected paths

The MCP server and Bearer-token API access are untouched by OIDC mode: MCP clients still authenticate with `MCP_API_KEY`, and `MCP_SERVICE_KEY` still authenticates MCP → backend.

### Reverting to local auth

Set `AUTH_MODE: local` in the HelmRelease (or drop the `AUTH_MODE` line); the `OIDC_*` values are ignored in local mode. This requires `AUTH_USERNAME`/`AUTH_PASSWORD_HASH` in the Bitwarden entry — generate the bcrypt hash inside the backend pod:

```bash
kubectl exec -it -n default deploy/homelable -c app -- \
  python3 -c "import bcrypt, getpass; print(bcrypt.hashpw(getpass.getpass('password: ').encode(), bcrypt.gensalt(12)).decode())"
```

## Proxmox VE import

Pulls hosts, VMs and LXC containers from the Proxmox REST API onto the canvas as typed nodes, with a `virtual` edge from each host to its guests. Re-imports update in place and never delete; a guest IP matching a previously scanned device merges onto it rather than duplicating.

The importer reads `/api2/json/nodes`, which returns **every cluster member** — so `PROXMOX_HOST=pve01.ewatkins.dev` pulls in pve02 and pve03 too, chained together with `cluster` edges.

`PROXMOX_VERIFY_TLS` stays `true`: the PVE certificate validates against the FQDN from inside the pod. Using the bare `10.35.1.1` address would fail verification (`IP address mismatch`) and force TLS verification off.

### Create the API token

In the Proxmox web UI:

1. **Datacenter → Permissions → Users → Add**: user `homelable`, realm `pve`.
2. **Datacenter → Permissions → API Tokens → Add**: user `homelable@pve`, token ID `homelable`, leave **Privilege Separation** checked. Copy the secret — Proxmox shows it once.
3. **Datacenter → Permissions → Add → API Token Permission**: path `/`, the token above, role **`PVEAuditor`**, **Propagate** enabled.

Step 3 is not optional with privilege separation on: a token with no ACL of its own makes `/qemu` and `/lxc` return an empty `200`, which looks exactly like a host with no guests. `PVEAuditor` is read-only — Homelable never writes to Proxmox.

The full token id must match `PROXMOX_TOKEN_ID` in the HelmRelease exactly, including the `user@realm!tokenid` shape.

## Homepage widget

`HOMEPAGE_API_KEY` enables `GET /api/v1/stats/summary`, which returns `nodes`, `online`, `offline`, `unknown`, `pending_devices`, `zigbee_devices` and `last_scan_at`. Callers send the key in an `X-API-Key` header; the endpoint 403s when the key is unset or wrong.

The [homepage](../homepage/) ConfigMap consumes it with a `customapi` widget pointed at the cluster-internal service, so the request never leaves the cluster. The key is read from `HOMEPAGE_VAR_HOMELABLE_KEY` in the **`homepage-secret`** Bitwarden entry — a separate entry from this app's, so the same value has to be added in both places.

## Notes

- Backend and MCP containers both load `homelable-secret`, so `MCP_SERVICE_KEY` (MCP → backend auth) matches automatically.
- Several settings are runtime-overridable from the UI and persisted to `scan_config.json` beside the SQLite DB, and that file **wins over the env var** at startup: `SCANNER_RANGES` (omitted from the HelmRelease for exactly this reason — a value there is inert on an existing PVC and only seeds a fresh one, where the upstream default is `192.168.1.0/24`), `STATUS_CHECKER_INTERVAL`, the `SERVICE_CHECK_*` and `SCANNER_HTTP_*` values, and `PROXMOX_SYNC_ENABLED` / `PROXMOX_SYNC_INTERVAL`. Treat those as first-boot defaults — Git and the running config can diverge silently. Credentials and connection config (`PROXMOX_HOST`, `PROXMOX_TOKEN_*`) are deliberately env-only and never written to disk.
- `CORS_ORIGINS` must stay pinned to `https://homelab.ewatkins.dev`; a wildcard is rejected outright in OIDC mode and a mismatched origin surfaces as `403 CSRF validation failed`.
- The backend scans the LAN from the pod network (SNAT to node IP); ARP-based discovery does not cross the L2 boundary, so scans rely on ICMP/TCP probes.
- If unprivileged scanning proves too limited, the alternative is labeling the namespace `pod-security.kubernetes.io/enforce: privileged` (like `media`) and restoring the `NET_RAW` capability.

## Links

- [GitHub Repository](https://github.com/Pouzor/homelable)
