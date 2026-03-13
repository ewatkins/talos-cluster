# [Envoy Gateway](https://gateway.envoyproxy.io/)

Envoy Gateway is a Kubernetes Gateway API implementation backed by Envoy Proxy, providing HTTP/HTTPS routing for cluster services via `HTTPRoute` and `GatewayClass` resources.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `envoy-gateway` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Chart: `envoy-gateway` (OCI) installed via Flux `OCIRepository`
- Provides the `internal` and `external` Gateway instances used by other applications for HTTPRoute-based routing
- CRDs are installed on first deploy and updated on upgrades

## Links

- [Documentation](https://gateway.envoyproxy.io/docs/)
- [GitHub Repository](https://github.com/envoyproxy/gateway)
