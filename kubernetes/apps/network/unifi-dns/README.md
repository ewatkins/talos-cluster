# [unifi-dns (ExternalDNS)](https://github.com/kubernetes-sigs/external-dns)

ExternalDNS configured with the UniFi webhook provider automatically synchronizes Kubernetes `HTTPRoute` and `Service` resources into DNS records on a UniFi controller for local LAN name resolution.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `unifi-dns` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `external-dns` v1.20.0 from `oci://ghcr.io/home-operations/charts-mirror/external-dns`
- Provider: webhook using `ghcr.io/kashalls/external-dns-unifi-webhook` v0.8.2
- Sources: `gateway-httproute`, `service`
- Domain filter: `ewatkins.dev`
- UniFi controller: `https://10.0.0.1`
- TXT record ownership prefix: `k8s.`
- Prometheus ServiceMonitor enabled

## Links

- [ExternalDNS Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [UniFi Webhook Repository](https://github.com/kashalls/external-dns-unifi-webhook)
- [GitHub Repository](https://github.com/kubernetes-sigs/external-dns)
