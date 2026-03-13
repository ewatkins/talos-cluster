# [MariaDB Operator](https://github.com/mariadb-operator/mariadb-operator)

The MariaDB Operator manages the lifecycle of MariaDB instances on Kubernetes via `MariaDB` and related custom resources, providing high availability, backup, and restore capabilities.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| CRD deployment | Separate HelmRelease | CRDs are deployed first to ensure they exist before the operator starts |
| Operator chart | `mariadb-operator` | Reconciles `MariaDB`, `Backup`, `Restore`, and related CRs |

## Links

- [Documentation](https://mariadb-operator.github.io/mariadb-operator/latest/)
- [Helm Chart](https://github.com/mariadb-operator/mariadb-operator/tree/main/deploy/charts/mariadb-operator)
- [GitHub Repository](https://github.com/mariadb-operator/mariadb-operator)
