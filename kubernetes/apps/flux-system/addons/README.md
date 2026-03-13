# flux-addons

Flux add-ons extend the core Flux installation with observability, alerting, and webhook-triggered reconciliation support.

## Created Resources

| Kind | Name |
| ---- | ---- |
| `PodMonitor` | `flux-system` |
| `PrometheusRule` | `flux-system` |
| `Provider` | `github` |
| `Alert` | `github` |
| `Receiver` | `github` |

## Components

### Monitoring

A `PodMonitor` and `PrometheusRule` are deployed to scrape Flux controller metrics and define alerting rules for Prometheus.

### Notifications

A Flux `Provider` and `Alert` are configured to post commit status notifications back to GitHub when reconciliations succeed or fail.

### Webhooks

A Flux `Receiver` is exposed via an HTTPRoute to accept push events from GitHub and trigger immediate reconciliation of the cluster.

## Links

- [Flux Notifications Documentation](https://fluxcd.io/flux/guides/notifications/)
- [Flux Webhook Receivers Documentation](https://fluxcd.io/flux/guides/webhook-receivers/)
