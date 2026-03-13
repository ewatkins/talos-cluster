# Crunchy Postgres Clusters

Postgres clusters managed by the [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/).

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
