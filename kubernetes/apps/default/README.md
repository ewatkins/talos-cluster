# default

General-purpose applications that do not belong to a more specific category namespace. All resources deploy into the `default` namespace.

Flux HelmRelease errors are forwarded to Alertmanager at `http://alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [alexandrie](alexandrie/README.md) | Wiki and knowledge base at `https://notes.ewatkins.dev`, backed by MariaDB Galera, in-pod RustFS object storage, and Keycloak OIDC |
