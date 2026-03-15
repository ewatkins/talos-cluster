# flux-system

The `flux-system` namespace contains the Flux CD GitOps engine and its supporting configuration. Flux watches `kubernetes/apps/` and reconciles cluster state from Git every 30 minutes; push events from GitHub trigger immediate reconciliation via a webhook receiver.

A Flux `Alert` in this namespace forwards error-severity events for all GitRepositories, HelmReleases, HelmRepositories, Kustomizations, and OCIRepositories to Alertmanager at `http://alertmanager-operated.observability.svc.cluster.local:9093`. DNS errors and socket timeouts are suppressed via an exclusion list.

## Apps

| App | Description |
| --- | --- |
| [flux-operator](flux-operator/README.md) | Kubernetes operator that manages the Flux CD installation lifecycle via the `FluxInstance` CRD |
| [flux-instance](flux-instance/README.md) | `FluxInstance` resource declaring the Flux distribution, components, and performance tuning |
| [addons](addons/README.md) | Prometheus monitoring, GitHub commit status notifications, and GitHub webhook receiver |
