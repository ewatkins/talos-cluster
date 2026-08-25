# [NetBox MCP](https://github.com/netboxlabs/netbox-mcp-server)

NetBox Labs' official MCP server, exposing the NetBox IPAM/DCIM database as agent tools. It is **read-only by design** — four tools, all of them GETs — and serves MCP over streamable HTTP so agents attach over the network instead of running a local stdio process.

| Tool | Purpose |
| --- | --- |
| `netbox_get_objects` | Retrieve NetBox core objects by type and filters |
| `netbox_get_object_by_id` | Fetch one object by type and numeric ID |
| `netbox_get_changelogs` | Query the change history / audit trail |
| `netbox_search_objects` | Global search across object types |

`object_type` is the dotted `app.model` form — `dcim.site`, `ipam.prefix`,
`virtualization.virtualmachine` — not the plural API path. Passing an invalid
value returns the full list of accepted types.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `docker.io/netboxlabs/netbox-mcp-server:1.2.1` | Pinned by digest |
| Helm chart | `bjw-s/app-template` | `chartRef` to the `app-template` OCIRepository |
| NetBox | `http://netbox.default.svc.cluster.local:8080/` | In-cluster Service — no hairpin through the gateway, no TLS on the internal hop |
| Service port | `8000` | The image's own `EXPOSE` |
| MCP endpoint | `https://netbox-mcp.ewatkins.dev/mcp` | The server's default HTTP path |
| Transport | `http` | `TRANSPORT=http`, `HOST=0.0.0.0` |
| Auth | `Authorization: Bearer <MCP_AUTH_TOKEN>` | Without this the transport is unauthenticated and exposes everything the NetBox token can read |
| Credentials | `netbox-mcp-secret` from Bitwarden Secrets Manager | `NETBOX_TOKEN`, `MCP_AUTH_TOKEN` |
| Runs as | UID/GID `1000` (`appuser` in the image) | |
| Root filesystem | Read-only | `emptyDir` at `/tmp`, `HOME=/tmp` |
| Gateway | `network/internal` (HTTPS) | Internal gateway |
| External DNS target | `internal.ewatkins.dev` | |

`ks.yaml` declares `dependsOn: netbox`, so Flux will not install this until NetBox itself is healthy.

## Credentials

The Bitwarden Secrets Manager item `netbox-mcp-secret` must expose two fields:

| Field | Notes |
| --- | --- |
| `NETBOX_TOKEN` | A NetBox API token with **Write enabled unchecked**. The server only ever reads; a read-only token enforces that at the API layer rather than trusting the client |
| `MCP_AUTH_TOKEN` | Any high-entropy string. Clients send it as `Authorization: Bearer <token>` |

Create the NetBox token in the UI under the admin user's **API Tokens**, or with `manage.py`.

## Connecting an agent

```json
{
  "mcpServers": {
    "netbox": {
      "type": "http",
      "url": "https://netbox-mcp.ewatkins.dev/mcp",
      "headers": { "Authorization": "Bearer <MCP_AUTH_TOKEN>" }
    }
  }
}
```
