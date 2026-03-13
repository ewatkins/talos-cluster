# [cloudflare-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the Cloudflare provider automatically synchronizes Kubernetes `DNSEndpoint` CRD resources into Cloudflare DNS records for the `ewatkins.dev` zone.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `cloudflare-dns` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `external-dns` v1.20.0 from `oci://ghcr.io/home-operations/charts-mirror/external-dns`
- Provider: Cloudflare
- Sources: `crd` (`DNSEndpoint` resources only)
- Records are proxied through Cloudflare (`--cloudflare-proxied`)
- Domain filter: `ewatkins.dev`
- TXT record ownership prefix: `k8s.`
- Prometheus ServiceMonitor enabled

## Links

- [Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
