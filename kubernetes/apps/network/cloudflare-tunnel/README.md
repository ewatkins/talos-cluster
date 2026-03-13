# [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

Cloudflare Tunnel (`cloudflared`) creates outbound-only encrypted connections from the cluster to the Cloudflare edge, enabling external access to internal services without requiring open inbound firewall ports or a public IP.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Replicas | 2 with rolling update | Two tunnels run in parallel for redundancy; Cloudflare load-balances between them |
| Protocol | QUIC with post-quantum encryption | Lower latency than HTTP/2 fallback; post-quantum protects against future decryption attacks |
| Credentials | `cloudflared-secret` | Contains the tunnel token; managed via ExternalSecrets from Bitwarden |

Traffic routing rules (which hostnames map to which cluster services) are configured in the Cloudflare Zero Trust dashboard, not in this deployment.

## Links

- [Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [GitHub Repository](https://github.com/cloudflare/cloudflared)
