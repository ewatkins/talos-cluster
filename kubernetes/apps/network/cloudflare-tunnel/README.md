# [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

`cloudflared` creates outbound-only encrypted connections from the cluster to the Cloudflare edge, enabling external access to internal services without requiring open inbound firewall ports or a public IP address.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `docker.io/cloudflare/cloudflared:2026.3.0` | |
| Replicas | `2` (RollingUpdate) | Two tunnels run in parallel for redundancy; Cloudflare load-balances between them |
| Transport protocol | QUIC | Lower latency than HTTP/2 fallback |
| Post-quantum encryption | Enabled (`TUNNEL_POST_QUANTUM=true`) | |
| HTTP/2 origin | Enabled (`TUNNEL_ORIGIN_ENABLE_HTTP2=true`) | |
| Metrics port | `8080` | Prometheus metrics at `/metrics`; 1-minute ServiceMonitor scrape interval |
| Auto-update | Disabled | |
| Memory limit | `256Mi` | |
| Run as user/group | `65534:65534` (nobody) | |

## Traffic Routing

The tunnel config at `app/configs/config.yaml` routes all traffic to the `external` Envoy Gateway service:

| Hostname | Backend |
| --- | --- |
| `ewatkins.dev` | `https://envoy-external.network.svc.cluster.local:443` |
| `*.ewatkins.dev` | `https://envoy-external.network.svc.cluster.local:443` |
| (catch-all) | `http_status:404` |

The tunnel's `originRequest.originServerName` is set to `external.ewatkins.dev` for TLS SNI.

## DNS

A `DNSEndpoint` resource creates a CNAME record `external.ewatkins.dev` pointing to `${SECRET_CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com`, managed by `cloudflare-dns`.

## Secrets

`cloudflared-secret` (from Bitwarden Secrets Manager via ExternalSecrets) contains `TUNNEL_ID` and the base64-encoded `credentials.json`.

## Links

- [Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [GitHub Repository](https://github.com/cloudflare/cloudflared)
