# external-secrets

The `external-secrets` namespace runs the External Secrets Operator, which syncs secrets from Bitwarden Secrets Manager into Kubernetes `Secret` resources at runtime. This decouples secret storage from the Git repository.

A Flux `Alert` in this namespace forwards error-severity HelmRelease events to Alertmanager at `http://alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [external-secrets](external-secrets/README.md) | External Secrets Operator with Bitwarden SDK server sidecar and `ClusterSecretStore` |
