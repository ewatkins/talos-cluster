# [Envoy Gateway](https://gateway.envoyproxy.io/)

Envoy Gateway implements the Kubernetes Gateway API using Envoy Proxy as the data plane. It provides two Gateway instances — `internal` and `external` — that applications reference via `HTTPRoute` (and `TCPRoute`) resources for HTTP/HTTPS routing.

## Deployment

Three Flux Kustomizations are used:

| Kustomization | Path | Purpose |
| --- | --- | --- |
| `envoy-gateway-operator` | `operator/` | Installs the Envoy Gateway Helm chart (CRDs created/replaced on upgrade) |
| `envoy-gateway-resources` | `gateway/` | Creates GatewayClasses, Gateways, EnvoyProxy configs, ClientTrafficPolicies, and the HTTP→HTTPS redirect |
| `envoy-gateway-monitoring` | `monitoring/` | Creates a ServiceMonitor scraping the `envoy-gateway-system` namespace |

`envoy-gateway-operator` depends on `network-certificates` and `cilium`. `envoy-gateway-resources` depends on both the operator and certificates.

## Gateways

| Gateway | GatewayClass | Service name | Listeners | DNS hostname |
| --- | --- | --- | --- | --- |
| `internal` | `envoy-internal` | (default) | `http:80`, `https:443`, `ssh:22` (TCPRoute) | `internal.ewatkins.dev` (Cilium LB IP `${INTERNAL}`) |
| `external` | `envoy-external` | `envoy-external` | `http:80`, `https:443` | `external.ewatkins.dev` (Cilium LB IP `${EXTERNAL}`) |

Both gateways terminate TLS using the `ewatkins-dev-production-tls` certificate from the `network` namespace. Routes from all namespaces are permitted.

## ClientTrafficPolicy

Both gateways share the same base policy:

| Setting | Value |
| --- | --- |
| TLS minimum version | `1.2` |
| Connection buffer limit | `100MB` |
| HTTP idle timeout | `120s` |
| `x-forwarded-client-cert` header | `AppendForward` |

The `internal` gateway additionally sets `http1.enableTrailers: false`.

## HTTP to HTTPS Redirect

An `HTTPRoute` named `http-to-https-redirect` applies a `301` redirect from port `80` to HTTPS on both the `internal` and `external` gateways.

## Links

- [Documentation](https://gateway.envoyproxy.io/docs/)
- [GitHub Repository](https://github.com/envoyproxy/gateway)
- [Helm Chart](https://gateway.envoyproxy.io/docs/install/install-helm/)
