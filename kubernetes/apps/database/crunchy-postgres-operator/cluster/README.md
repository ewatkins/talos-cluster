# Crunchy Postgres Clusters

PostgreSQL clusters managed by the [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/).
Each subdirectory is a separate `PostgresCluster` with its own Flux Kustomization.

| Directory | Cluster | Version | Purpose |
| --- | --- | --- | --- |
| [pg16](./pg16) | `crunchy-postgres` | 16 | General-purpose. Keycloak, Forgejo, Gatus, Grafana, Paperless, Patchmon |
| [pg17](./pg17) | `crunchy-postgres-17` | 17 | Migration target for the PG16 apps. Currently hosts Dispatcharr |
| [vector](./vector) | `crunchy-postgres-vector` | 16 | VectorChord (`vchord.so`) for Immich vector similarity search |

See [../README.md](../README.md) for operator-level configuration.

## pg17 and the migration

`pg17` exists because Dispatcharr version-checks the server at startup and
refuses anything below PostgreSQL 17, while `pg16` serves seven other
applications and is not worth a major-version upgrade on that app's account.

It is deliberately generic rather than Dispatcharr-specific — it carries a
superuser, pgBouncer and a comparable backup posture to `pg16`, so the
remaining apps can be moved onto it one at a time. To migrate an app:

1. Add its user and database to `pg17/cluster.yaml` under `users`
2. Repoint the app's `ExternalSecret` at `crunchy-postgres-17-pguser-<user>`
3. Change its `ks.yaml` `dependsOn` to `crunchy-postgres-17`
4. Dump and restore the data

## Backup layout

Repo numbering is not consistent between clusters, which matters when reading
each `externalsecret.yaml` — the pgBackRest credential keys are numbered per
repo, so they are not interchangeable:

| Cluster | repo1 | repo2 | repo3 |
| --- | --- | --- | --- |
| `pg16` | NFS volume | Garage (S3) | Cloudflare R2 |
| `pg17` | Garage (S3) | Cloudflare R2 | — |
| `vector` | NFS volume | — | — |

`pg17` has no NFS repo because that would require a new export on the NAS; it
uses Garage plus offsite R2 instead. `pg16` and `pg17` share the `crunchy-pgo`
bucket but write under different path prefixes, so their backups cannot collide.

`pg17` does not set `repoN-cipher-pass`, so unlike `pg16` its R2 backups are
unencrypted at rest — worth addressing before migrating production data onto it.

## Repo host resources

All clusters set `backups.pgbackrest.repoHost.resources`. Without a CPU request
the repo host runs as BestEffort and gets the minimum CPU weight; under node
contention it misses the hardcoded 1s `pgbackrest server-ping` liveness timeout
and is killed mid-backup, which silently breaks backups and WAL archiving. PGO
does not expose that probe, so guaranteeing CPU is the only fix.

## Bootstrapping a New Cluster

When creating a cluster from a data source (e.g., restoring from a backup),
temporarily remove the `dataSource` field during initial bootstrap:

```yaml
patches:
  - patch: |-
      - op: remove
        path: /spec/dataSource
    target:
      kind: PostgresCluster
```

Remove the patch after the cluster is running and the data source has been applied.

## Backup Job History

To reduce noise from completed backup jobs, set `successfulJobsHistoryLimit: 0`
on the backup CronJobs:

```sh
kubectl get cronjob --all-namespaces \
  -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" --no-headers | \
  grep -E 'repo[0-9]+-(diff|full|incr)$' | \
  xargs -n2 sh -c 'kubectl patch cronjob $1 -n $0 --type=merge \
    -p "{\"spec\": {\"successfulJobsHistoryLimit\": 0}}"'
```

## Links

- [PGO Documentation](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- [GitHub Repository](https://github.com/CrunchyData/postgres-operator)
