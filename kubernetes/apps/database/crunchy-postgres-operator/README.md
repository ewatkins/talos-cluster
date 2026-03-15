# [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/)

PGO manages the full lifecycle of highly available PostgreSQL clusters on Kubernetes via `PostgresCluster` and related custom resources. It handles provisioning, scaling, connection pooling (PgBouncer), monitoring, and automated backups.

## Operator Configuration

| Setting | Value |
| --- | --- |
| Chart source | OCI: `oci://registry.developers.crunchydata.com/crunchydata/pgo` |
| Chart version | `6.0.0` |
| Operator replicas | 2 |
| Topology spread | One replica per zone (`topology.kubernetes.io/zone`), `DoNotSchedule` |
| Monitoring | Enabled (Prometheus PodMonitor via `exporter` port) |

## Flux Kustomizations

| Kustomization | Path | Depends On |
| --- | --- | --- |
| `crunchy-postgres-operator` | `app/` | — |
| `crunchy-postgres-operator-cluster` | `cluster/` | operator, external-secrets-stores |
| `crunchy-postgres-operator-secretstore` | `stores/` | cluster, external-secrets |
| `crunchy-userinit-controller` | `userinit-controller/` | cluster |
| `crunchy-postgres-users` | `users/` | cluster |
| `crunchy-postgres-vector` | `vector-cluster/` | operator |

## Main PostgreSQL Cluster (`crunchy-postgres`)

| Setting | Value |
| --- | --- |
| Image | `registry.developers.crunchydata.com/crunchydata/crunchy-postgres:ubi9-16.11-2550` |
| PostgreSQL version | 16 |
| Replicas | 3 |
| Data storage | 2 Gi per instance, `nfs-fast` StorageClass |
| Topology spread | One instance per node (`kubernetes.io/hostname`), `DoNotSchedule` |
| Synchronous mode | Enabled (`synchronous_mode: true`, `synchronous_commit: on`) |
| `max_connections` | 500 |
| `max_wal_size` | 5 GB |
| Service type | LoadBalancer (IP from `${CRUNCHY_POSTGRES}` annotation) |

### PgBouncer Proxy

| Setting | Value |
| --- | --- |
| Replicas | 3 |
| Port | 5432 |
| Service type | LoadBalancer |
| Pool mode | session |
| `default_pool_size` | 100 |
| `max_client_conn` | 500 |
| `client_tls_sslmode` | prefer |

### Databases and Users

| User | Database |
| --- | --- |
| `postgres` (superuser) | `postgres` |
| `keycloak-admin` | `keycloak` |
| `forgejo-admin` | `forgejo` |
| `gatus-admin` | `gatus` |
| `grafana-admin` | `grafana` |
| `paperless-admin` | `paperless` |
| `outline-admin` | `outline` |

### Backups (pgBackRest)

| Repo | Type | Destination | Retention | Schedule |
| --- | --- | --- | --- | --- |
| `repo1` | NFS PVC | `caspian.local:/mnt/user/crunchy-postgres` | 30 days | Full Sun 01:30, Diff Mon–Sat 01:30, Incr hourly |
| `repo2` | S3 (Minio) | `s3.ewatkins.dev`, bucket `crunchy-pgo` | 30 days | Full Sun 01:15, Diff Mon–Sat 01:15, Incr hourly |
| `repo3` | S3 (Cloudflare R2) | `${SECRET_R2_ENDPOINT}`, bucket `crunchy-pgo` | 7 days | Full Sun 02:30, Incr Mon–Sat every 2nd day |

Compression: `bz2` level 9. Repos 1 and 3 use cipher encryption. Data source for cluster bootstrap is `repo3` (R2).

### Secrets

The `crunchy-postgres-secret` ExternalSecret (sourced from Bitwarden) provides:
- Minio S3 access key and secret (`repo2`)
- Cloudflare R2 access key and secret (`repo3`)
- pgBackRest cipher passphrase (repos 1 and 3)

### Secret Store

A `ClusterSecretStore` named `crunchy-postgres` is registered so other namespaces can pull PGO-generated user secrets (e.g., `crunchy-postgres-pguser-*`) from the `database` namespace via ExternalSecrets. Access is granted through the `external-secrets-pg` ServiceAccount, ClusterRole, and ClusterRoleBinding.

## Vector PostgreSQL Cluster (`crunchy-postgres-vector`)

A separate PostgreSQL 16 cluster with the [VectorChord](https://github.com/tensorchord/VectorChord) extension for vector similarity search.

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/budimanjojo/crunchy-postgres-vectorchord:16-0.4.3` |
| Replicas | 3 |
| Data storage | 5 Gi per instance, `openebs-hostpath` |
| WAL storage | 5 Gi per instance, `openebs-hostpath` |
| Preloaded library | `vchord.so` |
| User | `immich` → database `immich` |
| Init SQL | Installs `vchord` and `earthdistance` extensions in the `immich` database |
| Backup repo | NFS PVC (`caspian.local:/mnt/user/crunchy-postgres-vector`), 14-day retention |

## User Management

- **`crunchy-userinit-controller`** (`crunchy-userinit-controller` chart v0.0.4): runs post-create init logic for PGO cluster users when the `crunchy-userinit.ramblurr.github.com/enabled: "true"` label is set on a `PostgresCluster`.
- **`crunchy-users`** (`crunchy-users-helm` chart v1.0.8): manages database users and passwords via Helm values.

## Monitoring and Health

- PodMonitor scrapes the `exporter` port on pods labelled `postgres-operator.crunchydata.com/crunchy-postgres-exporter: "true"`, adding `pg_cluster`, `deployment`, `role`, and `instance` labels.
- Gatus health check: TCP connect to `crunchy-postgres-pgbouncer.database.svc.cluster.local:5432` every 1 minute.

## Bootstrapping Notes

When creating a cluster from a data source (restoring from backup), temporarily remove the `dataSource` field with a Kustomize patch during initial bootstrap. Remove the patch after the cluster is healthy.

To suppress completed backup job history:

```sh
kubectl get cronjob --all-namespaces \
  -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" --no-headers | \
  grep -E 'repo[0-9]+-(diff|full|incr)$' | \
  xargs -n2 sh -c 'kubectl patch cronjob $1 -n $0 --type=merge \
    -p "{\"spec\": {\"successfulJobsHistoryLimit\": 0}}"'
```

## Links

- [Documentation](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- [GitHub Repository](https://github.com/CrunchyData/postgres-operator)
- [Helm Chart (OCI)](https://registry.developers.crunchydata.com/crunchydata/pgo)
