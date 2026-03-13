# Flux Add-ons

Supporting resources that extend the core Flux installation with observability, GitHub status reporting, and webhook-triggered reconciliation.

## Components

| Resource | Kind | Purpose |
| --- | --- | --- |
| `flux-system` PodMonitor | `PodMonitor` | Scrapes metrics from all Flux controllers into Prometheus |
| `flux-system` PrometheusRule | `PrometheusRule` | Defines alerting rules for stalled or failed reconciliations |
| `github` Provider | Flux `Provider` | Posts commit status checks to GitHub PRs |
| `github` Alert | Flux `Alert` | Triggers the Provider on reconciliation success or failure |
| `github` Receiver | Flux `Receiver` | Accepts GitHub push webhooks to trigger immediate reconciliation |

### Webhook Setup

The `Receiver` is exposed via an `HTTPRoute` on the Envoy Gateway. When a push is made to the `talos-cluster` repository, GitHub calls the receiver endpoint and Flux begins reconciling immediately — without waiting for the 30-minute polling interval.

## Links

- [Flux Notifications Documentation](https://fluxcd.io/flux/guides/notifications/)
- [Flux Webhook Receivers Documentation](https://fluxcd.io/flux/guides/webhook-receivers/)
