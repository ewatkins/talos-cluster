# [MariaDB Operator](https://github.com/mariadb-operator/mariadb-operator)

The MariaDB Operator manages the lifecycle of MariaDB instances on Kubernetes via `MariaDB`, `MaxScale`, `Database`, `User`, and `Grant` custom resources. A 3-node Galera cluster with MaxScale proxy is deployed in the `database` namespace.

## Operator Deployment

| Setting | Value |
| --- | --- |
| CRDs chart | `mariadb-operator-crds` v26.3.0 |
| Operator chart | `mariadb-operator` v25.10.4 |
| Chart source | `mariadb` HelmRepository |
| Deployment order | CRDs deployed first (`mariadb-operator-crds` Kustomization), then operator, then cluster |

## MariaDB Cluster Configuration

| Setting | Value |
| --- | --- |
| Replicas | 3 |
| High availability | Galera (synchronous multi-master replication) |
| Storage | 5 Gi per node, `openebs-hostpath` StorageClass |
| Service type | LoadBalancer (IP from `${MARIADB}` variable annotation) |
| Transaction isolation | `READ-COMMITTED` |
| Metrics | Enabled |
| Root secret | `mariadb-root-secret` (sourced from Bitwarden via ExternalSecret) |
| Galera pod sync timeout | 30 minutes |
| Galera cluster bootstrap timeout | 40 minutes |

## MaxScale Proxy Configuration

| Setting | Value |
| --- | --- |
| Replicas | 2 |
| Router | `readwritesplit` on port 3306 |
| Monitor interval | 2 seconds |
| Cooperative monitoring | `majority_of_all` |
| Admin port | 8989 |
| Admin GUI | Enabled |
| Service type (data) | LoadBalancer (IP from `${MAXSCALE}` variable annotation) |
| Service type (GUI) | LoadBalancer (IP from `${MAXSCALE_GUI}` variable annotation) |
| GUI URL | `https://maxscale.ewatkins.dev` (internal gateway) |
| Config sync database | `mysql`, interval 5 s, timeout 10 s |
| Connection secret | `mxs-galera-conn` |
| Metrics | Enabled |
| Gatus health check | TCP connect to `10.40.0.120:3306` every 1 minute |

## Databases and Users

The following databases, users, and grants are managed as operator CRs:

| Database | User | Notes |
| --- | --- | --- |
| `auraskills` | `auraskills` | Minecraft AuraSkills plugin |
| `essentialsxgui` | `essentialsxgui` | Minecraft EssentialsX GUI plugin |
| `jobs` | `jobs` | Minecraft Jobs plugin |
| `luckperms` | `luckperms` | Minecraft LuckPerms plugin |
| `playerpoints` | `playerpoints` | Minecraft PlayerPoints plugin |
| `wildstacker` | `wildstacker` | Minecraft WildStacker plugin |
| — | `pterodactyl` | Pterodactyl panel (database managed externally) |

All databases use `utf8` character set with `utf8_general_ci` collation. User secrets are sourced from Bitwarden via ExternalSecrets (refreshed every 15 minutes).

## Links

- [Documentation](https://mariadb-operator.github.io/mariadb-operator/latest/)
- [GitHub Repository](https://github.com/mariadb-operator/mariadb-operator)
- [Helm Chart](https://github.com/mariadb-operator/mariadb-operator/tree/main/deploy/charts/mariadb-operator)
