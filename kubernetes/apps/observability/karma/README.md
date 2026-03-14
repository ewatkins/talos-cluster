# [Karma](https://github.com/prymitive/karma)

Alert dashboard for Prometheus Alertmanager. Aggregates and displays alerts from one or more Alertmanager instances in a filterable, searchable UI.

## Configuration

Karma runs 3 replicas spread across nodes via topology spread constraints (`maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule`), ensuring it remains available even if a node goes down. It depends on `kube-prometheus-stack` and reads alert state from Alertmanager.

The Alertmanager URL and any additional configuration are set in the `karma-configmap` ConfigMap. Karma reloads automatically when that ConfigMap changes (via Reloader).

## Links

- [Documentation](https://github.com/prymitive/karma/blob/main/docs/CONFIGURATION.md)
- [GitHub Repository](https://github.com/prymitive/karma)
- [Helm Chart](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template) (deployed via `app-template`)
