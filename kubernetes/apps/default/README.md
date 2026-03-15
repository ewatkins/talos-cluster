# default

General-purpose applications that do not belong to a more specific category namespace. All resources deploy into the `default` namespace.

Flux HelmRelease errors are forwarded to Alertmanager at `http://alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [outline](outline/README.md) | Team knowledge base and wiki (`outlinewiki/outline:1.5.0`) at `https://notes.ewatkins.dev`, backed by PostgreSQL, Dragonfly, Minio, and Keycloak OIDC |
