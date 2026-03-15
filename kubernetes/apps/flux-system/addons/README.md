# Flux Add-ons

Supporting resources that extend the core Flux installation with Prometheus observability, GitHub commit status reporting, and webhook-triggered reconciliation.

## Flux Kustomization

| Setting | Value |
| --- | --- |
| Kustomization name | `flux-addons` |
| Namespace | `flux-system` |
| Path | `kubernetes/apps/flux-system/addons/app` |
| Interval | 30m |
| Retry interval | 1m |
| Timeout | 5m |
| Wait | false |

## Monitoring

### PodMonitor

A `PodMonitor` named `flux-system` scrapes the `http-prom` port from all running Flux controller pods in the `flux-system` namespace. Monitored controllers:

- `helm-controller`
- `source-controller`
- `kustomize-controller`
- `notification-controller`
- `image-automation-controller`
- `image-reflector-controller`

### PrometheusRule

A `PrometheusRule` named `flux-rules` defines two alerting rules:

| Alert | Expression | For | Severity |
| --- | --- | --- | --- |
| `FluxComponentAbsent` | `absent(up{job=~".*flux-system.*"} == 1)` | 15m | critical |
| `FluxReconciliationFailure` | `gotk_reconcile_condition{status="False",type="Ready"}` with deletion check | 15m | critical |

## GitHub Notifications

A Flux `Provider` posts commit status checks to the `ewatkins/talos-cluster` GitHub repository. A Flux `Alert` triggers it on all `info`-severity events from every `GitRepository`, `Kustomization`, and `HelmRelease`.

| Resource | Name | Details |
| --- | --- | --- |
| `Provider` | `github` | Type: `github`, address: `https://github.com/ewatkins/talos-cluster` |
| `Alert` | `talos-cluster-github` | Severity: `info`, sources: all `GitRepository`, `Kustomization`, `HelmRelease` |
| `ExternalSecret` | `github-token-secret` | Pulls `token` from `ClusterSecretStore/bitwarden-secrets-manager`, refresh 15m |

## GitHub Webhook Receiver

A Flux `Receiver` listens for `ping` and `push` events from GitHub and immediately triggers reconciliation of the `talos-cluster` `GitRepository` and the `cluster` and `cluster-apps` `Kustomization` resources.

The receiver is exposed externally via an `HTTPRoute` on the Envoy Gateway (`parentRef: network/external`, section `https`).

| Resource | Name | Details |
| --- | --- | --- |
| `Receiver` | `github-receiver` | Type: `github`, events: `ping`, `push` |
| `HTTPRoute` | `flux-webhook` | Host: `flux-webhook.ewatkins.dev`, path prefix `/hook/`, backend: `webhook-receiver:80` |
| `DNSEndpoint` | `flux-webhook` | CNAME `flux-webhook.ewatkins.dev` → `${SECRET_CLOUDFLARE_TUNNEL_ID}.cfargotunnel.com`, TTL 1 |
| `ExternalSecret` | `github-webhook-token-secret` | Pulls `token` from `ClusterSecretStore/bitwarden-secrets-manager`, refresh 15m |

The `HTTPRoute` is annotated to publish the DNS record via external-dns using the Cloudflare tunnel target.

## Links

- [Flux Notifications Documentation](https://fluxcd.io/flux/guides/notifications/)
- [Flux Webhook Receivers Documentation](https://fluxcd.io/flux/guides/webhook-receivers/)
