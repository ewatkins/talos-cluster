# [Proxmox MCP Plus](https://github.com/RekklesNA/ProxmoxMCP-Plus)

An MCP server that exposes Proxmox VE as agent tools — nodes, VMs, LXC containers, storage, snapshots, backups, ISO images, cluster health and task logs. It talks to `pve01.ewatkins.dev:8006` with an API token and serves MCP over streamable HTTP so agents attach over the network instead of running a local stdio process.

The image defaults to the OpenAPI bridge on port 8811; `PROXMOX_MCP_MODE=mcp-http` switches the entrypoint to the native MCP listener on port 8000 instead.

No `config.json` is baked into the image, so the config loader takes its fallback path and reads every setting from the environment.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/rekklesna/proxmoxmcp-plus:0.5.14` | Pinned by digest |
| Helm chart | `bjw-s/app-template` | `chartRef` to the `app-template` OCIRepository |
| Proxmox host | `pve01.ewatkins.dev:8006` | `/nodes` returns every cluster member, so pve02 and pve03 come along |
| TLS verification | `PROXMOX_VERIFY_SSL=true` | The loader rejects `false` outright unless `PROXMOX_DEV_MODE=true`, so the FQDN (not the bare IP) has to be used |
| Service port | `8000` | |
| MCP endpoint | `https://proxmox-mcp.ewatkins.dev/mcp` | FastMCP's default streamable-http path |
| Transport | `mcp-http` / `STREAMABLE_HTTP` | `PROXMOX_MCP_MODE=mcp-http` |
| Allowed hosts | ingress hostname + Service DNS + localhost | `MCP_ALLOWED_HOSTS`; DNS-rebinding protection validates the `Host` header, so an unlisted name gets rejected |
| Tools exposed | 47 | Server reports itself as `ProxmoxMCP` 1.29.0 |
| Client auth | Bearer token | `MCP_API_KEY`; without it the server serves tools to anyone who can reach the endpoint |
| Command policy | `deny_all` | `execute_*` shell tools are disabled entirely |
| High-risk policy | `enforce` + approval token | Deletes, rollbacks and restores require the agent to pass `COMMAND_POLICY_HIGH_RISK_APPROVAL_TOKEN` |
| Job history | `/tmp/proxmox-jobs.sqlite3` | Default is relative to `/app`, which is read-only |
| Credentials | `proxmox-mcp-secret` from Bitwarden Secrets Manager | |
| CPU request | `10m` | |
| Memory limit | `512Mi` | |
| Root filesystem | Read-only | `emptyDir` at `/tmp`, `HOME=/tmp` |
| Gateway | `network/internal` (HTTPS) | Internal gateway |
| External DNS target | `internal.ewatkins.dev` | |
| HSTS | `max-age=31449600; includeSubDomains` | Applied via response header modifier |

## Credentials

Create a Proxmox API token `mcp@pve!mcp` (Datacenter → Permissions → API Tokens) and give the `mcp@pve` user a role with at least `VM.Audit`, `Sys.Audit`, `Datastore.Audit` — plus `VM.PowerMgmt`, `VM.Allocate`, `VM.Snapshot` and `Datastore.AllocateSpace` if the agent should be allowed to act rather than just read. Leave **Privilege Separation** unchecked so the token inherits the user's permissions.

The Bitwarden Secrets Manager item `proxmox-mcp-secret` must expose three fields:

| Field | Notes |
| --- | --- |
| `token_value` | The secret half shown once when the API token is created |
| `mcp_api_key` | Bearer token clients send in `Authorization`. Generate with `openssl rand -hex 32`. Must be ASCII with no whitespace |
| `approval_token` | Passed by the agent to unlock high-risk tools. Generate the same way |

## Connecting an agent

```json
{
  "mcpServers": {
    "proxmox": {
      "type": "http",
      "url": "https://proxmox-mcp.ewatkins.dev/mcp",
      "headers": {
        "Authorization": "Bearer <mcp_api_key>"
      }
    }
  }
}
```

In-cluster clients can skip the gateway and use `http://proxmox-mcp.mcp.svc.cluster.local:8000/mcp`.

## Permissions

Three independent layers:

- **Proxmox role** — the hard ceiling. Whatever the `mcp@pve` token cannot do, no tool can do.
- `COMMAND_POLICY_MODE` — `deny_all` (current), `allowlist` or `audit_only`. Governs the `execute_*` tools that run shell commands through the QEMU guest agent. `deny_all` blocks them outright; `allowlist` also needs `COMMAND_POLICY_ALLOW_PATTERNS`.
- `COMMAND_POLICY_HIGH_RISK_*` — governs `delete_vm`, `delete_container`, `delete_snapshot`, `rollback_snapshot`, `restore_backup`, `delete_backup`, `delete_iso` and `update_container_ssh_keys`. Mode is `enforce` and an approval token is required, so those tools fail with `requires an approval token` unless the agent passes the matching value as the tool's own `approval_token` argument.

To make the server read-only, set `COMMAND_POLICY_HIGH_RISK_MODE` to `enforce` and simply never hand the approval token to an agent — or tighten the Proxmox role to the `*.Audit` privileges only.

## Flux Kustomizations

| Kustomization | Path | Interval |
| --- | --- | --- |
| `proxmox-mcp` | `kubernetes/apps/mcp/proxmox-mcp/app` | 1h |

## Links

- [GitHub Repository](https://github.com/RekklesNA/ProxmoxMCP-Plus)
- [Proxmox API token docs](https://pve.proxmox.com/wiki/User_Management#pveum_tokens)
