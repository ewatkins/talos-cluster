# [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

Cloudflare Tunnel (`cloudflared`) creates an outbound-only encrypted tunnel from the cluster to the Cloudflare edge, enabling external access to internal services without opening inbound firewall ports.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `cloudflare-tunnel` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `docker.io/cloudflare/cloudflared` v2026.3.0
- Deployed via `bjw-s/app-template` chart v3.7.3
- 2 replicas with rolling update strategy for high availability
- Transport protocol: QUIC with post-quantum encryption enabled
- Tunnel credentials stored in the `cloudflared-secret` Secret
- Prometheus ServiceMonitor scrapes `/metrics` endpoint

## Links

- [Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [GitHub Repository](https://github.com/cloudflare/cloudflared)
