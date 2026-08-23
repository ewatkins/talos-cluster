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
| Scanner ranges | `192.168.40.0/24` | Adjust `SCANNER_RANGES` in the HelmRelease |
| Data PVC | `homelable-data`, 2Gi (`openebs-hostpath`) | SQLite DB + uploads at `/app/data`; ⚠️ Talos node upgrades wipe OpenEBS local PVs |
| Auth | OIDC via Keycloak (`AUTH_MODE=oidc`) | Client `homelable` on the `master` realm; replaces local username/password login |
| Secret | Bitwarden entry `homelable-secret` | Synced via ExternalSecrets into `homelable-secret` |

## Bitwarden secret

Create a Secrets Manager entry named `homelable-secret` whose value is JSON; keys become backend env vars:

```json
{
  "SECRET_KEY": "<openssl rand -hex 32>",
  "OIDC_CLIENT_SECRET": "<from the Keycloak client's Credentials tab>",
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

## Notes

- Backend and MCP containers both load `homelable-secret`, so `MCP_SERVICE_KEY` (MCP → backend auth) matches automatically.
- `CORS_ORIGINS` must stay pinned to `https://homelab.ewatkins.dev`; a wildcard is rejected outright in OIDC mode and a mismatched origin surfaces as `403 CSRF validation failed`.
- The backend scans the LAN from the pod network (SNAT to node IP); ARP-based discovery does not cross the L2 boundary, so scans rely on ICMP/TCP probes.
- If unprivileged scanning proves too limited, the alternative is labeling the namespace `pod-security.kubernetes.io/enforce: privileged` (like `media`) and restoring the `NET_RAW` capability.

## Links

- [GitHub Repository](https://github.com/Pouzor/homelable)
