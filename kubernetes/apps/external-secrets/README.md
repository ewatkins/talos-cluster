# external-secrets

The `external-secrets` namespace runs the External Secrets Operator, which syncs secrets from Bitwarden Secrets Manager into Kubernetes `Secret` resources at runtime. This decouples secret storage from the Git repository.

## Apps

| App | Description |
| --- | --- |
| [external-secrets](external-secrets/README.md) | External Secrets Operator with Bitwarden SDK server sidecar and `ClusterSecretStore` |
