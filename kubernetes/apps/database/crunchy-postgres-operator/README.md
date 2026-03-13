# [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/)

PGO manages the full lifecycle of highly available PostgreSQL clusters on Kubernetes — provisioning, scaling, backups, monitoring, and user management — via `PostgresCluster` and related custom resources.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Operator replicas | 2 | Spread across topology zones to survive a node failure |
| User management | `crunchy-users-helm` chart | Manages database users and passwords via Helm values |
| Monitoring | Prometheus ServiceMonitor | Exposes per-cluster metrics via the PGO exporter sidecar |

See [cluster/README.md](cluster/README.md) for notes on managing PostgreSQL cluster instances and handling Patroni failovers.

## Links

- [Documentation](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- [GitHub Repository](https://github.com/CrunchyData/postgres-operator)
- [Helm Chart](https://github.com/CrunchyData/postgres-operator/tree/master/helm/install)
