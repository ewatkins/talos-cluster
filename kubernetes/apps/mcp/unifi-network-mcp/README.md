# [UniFi Network MCP](https://github.com/sirkirby/unifi-network-mcp)

An MCP server that exposes the UniFi Network controller as agent tools — clients, devices, firewall rules, port forwards, VLANs, QoS, traffic routes, VPN, stats and events. It talks to the UDM at `10.0.0.1` and serves MCP over streamable HTTP so agents attach over the network instead of running a local stdio process.

The container runs as PID 1, which makes the shared transport layer skip stdio and bind the HTTP listener only.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/sirkirby/unifi-network-mcp:0.24.1` | Pinned by digest |
| Helm chart | `bjw-s/app-template` 5.0.1 | `chartRef` to the `app-template` OCIRepository |
| UniFi controller | `10.0.0.1:443`, site `default` | `UNIFI_VERIFY_SSL=false` — the UDM serves a self-signed cert |
| Service port | `3000` | |
| MCP endpoint | `https://unifi-mcp.ewatkins.dev/mcp` | FastMCP's default streamable-http path |
| Transport | `streamable-http` | `UNIFI_MCP_HTTP_ENABLED=true` |
| Allowed hosts | ingress hostname + Service DNS + localhost | `UNIFI_MCP_ALLOWED_HOSTS`; DNS-rebinding protection validates the `Host` header, so an unlisted name gets rejected |
| Tool registration | `lazy` | Meta-tools registered up front, the rest loaded on demand to keep agent context small |
| Permission mode | `confirm` | Mutating tools return a preview; the agent must re-call with `confirm=true` to apply |
| Credentials | `unifi-network-mcp-secret` from Bitwarden Secrets Manager | `UNIFI_USERNAME`, `UNIFI_PASSWORD`, `UNIFI_API_KEY` |
| CPU request | `10m` | |
| Memory limit | `512Mi` | |
| Root filesystem | Read-only | `emptyDir` at `/tmp`, `HOME=/tmp` |
| Gateway | `network/internal` (HTTPS) | Internal gateway |
| External DNS target | `internal.ewatkins.dev` | |
| HSTS | `max-age=31449600; includeSubDomains` | Applied via response header modifier |

## Credentials

The Bitwarden Secrets Manager item `unifi-network-mcp-secret` must expose three fields:

| Field | Required | Notes |
| --- | --- | --- |
| `username` | Yes | A **local** UniFi admin account. Ubiquiti SSO accounts do not authenticate against the controller API |
| `password` | Yes | Password for that local account |
| `api_key` | Yes (may be empty) | UniFi API key. Optional to the app, but the ExternalSecret template references it, so the field has to exist |

## Connecting an agent

```json
{
  "mcpServers": {
    "unifi-network": {
      "type": "http",
      "url": "https://unifi-mcp.ewatkins.dev/mcp"
    }
  }
}
```

In-cluster clients can skip the gateway and use `http://unifi-network-mcp.mcp.svc.cluster.local:3000/mcp`.

## Permissions

Two independent controls, both set through environment variables:

- `UNIFI_TOOL_PERMISSION_MODE` — `confirm` (current) or `bypass`. Only affects mutating tools.
- `UNIFI_POLICY_<ACTION>` / `UNIFI_POLICY_NETWORK_<ACTION>` / `UNIFI_POLICY_NETWORK_<CATEGORY>_<ACTION>` — hard on/off gates, most specific wins. None are set, so every action is reachable behind the confirmation step.

To make the server read-only, add `UNIFI_POLICY_CREATE`, `UNIFI_POLICY_UPDATE` and `UNIFI_POLICY_DELETE` set to `"false"`.

## Flux Kustomizations

| Kustomization | Path | Interval |
| --- | --- | --- |
| `unifi-network-mcp` | `kubernetes/apps/mcp/unifi-network-mcp/app` | 1h |

## Links

- [GitHub Repository](https://github.com/sirkirby/unifi-network-mcp)
- [Tool index](https://sirkirby.github.io/unifi-network-mcp/tool-index)
- [Permission system](https://sirkirby.github.io/unifi-network-mcp/permissions)
