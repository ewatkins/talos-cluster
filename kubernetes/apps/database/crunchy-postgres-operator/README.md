# [Crunchy Postgres Operator (PGO)](https://access.crunchydata.com/documentation/postgres-operator/latest/)

PGO, the Postgres Operator from Crunchy Data, manages the full lifecycle of highly available PostgreSQL clusters on Kubernetes, including provisioning, backups, monitoring, and user management.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `crunchy-postgres-operator` |
| [`HelmRelease`][ref-helm-release] | `crunchy-users` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Operator chart: `pgo` v6.0.0 from `oci://registry.developers.crunchydata.com/crunchydata/pgo`
- Runs 2 operator replicas spread across topology zones
- Prometheus monitoring is enabled
- User management uses the `crunchy-users-helm` chart v1.0.8
- See [cluster/README.md](cluster/README.md) for notes on managing PostgreSQL clusters

## Links

- [Documentation](https://access.crunchydata.com/documentation/postgres-operator/latest/)
- [GitHub Repository](https://github.com/CrunchyData/postgres-operator)
- [Helm Chart](https://github.com/CrunchyData/postgres-operator/tree/master/helm/install)
