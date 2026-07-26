# Crunchy Postgres Clusters

PostgreSQL clusters managed by the [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/).

Two clusters are defined here:

- **`crunchy-postgres`** — general-purpose PostgreSQL 16 cluster used by Keycloak, Forgejo, Gatus, Grafana, Paperless, and Outline
- **`crunchy-postgres-vector`** — PostgreSQL 16 cluster with VectorChord (`vchord.so`) for Immich vector similarity search

See [../README.md](../README.md) for full configuration details on both clusters including replica counts, storage, backup schedules, and user lists.

## Bootstrapping a New Cluster

When creating a cluster from a data source (e.g., restoring from a backup), temporarily remove the `dataSource` field during initial bootstrap:

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

To reduce noise from completed backup jobs, set `successfulJobsHistoryLimit: 0` on the backup CronJobs:

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
