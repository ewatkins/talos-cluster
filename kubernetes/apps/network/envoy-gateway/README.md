# [Envoy Gateway](https://gateway.envoyproxy.io/)

Envoy Gateway implements the Kubernetes Gateway API using Envoy Proxy as the data plane. It provides `internal` and `external` Gateway instances that other applications reference via `HTTPRoute` resources for HTTP/HTTPS routing.

## Configuration

| Gateway | Purpose |
| --- | --- |
| `internal` | Routes accessible only from within the LAN |
| `external` | Routes accessible externally via the Cloudflare tunnel |

Applications add routing by creating `HTTPRoute` resources that reference one of these Gateways. CRDs are installed automatically on first deploy and updated on upgrades.

## Links

- [Documentation](https://gateway.envoyproxy.io/docs/)
- [GitHub Repository](https://github.com/envoyproxy/gateway)
