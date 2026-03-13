# [MariaDB Operator](https://github.com/mariadb-operator/mariadb-operator)

The MariaDB Operator automates the management of MariaDB instances on Kubernetes, providing lifecycle management, high availability, and backup support via custom resources.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `mariadb-operator-crds` |
| [`HelmRelease`][ref-helm-release] | `mariadb-operator` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- CRDs chart: `mariadb-operator-crds` v25.10.4 from the `mariadb` Helm repository
- Operator chart: `mariadb-operator` v25.10.4 from the `mariadb` Helm repository
- CRDs are deployed separately to ensure they are available before the operator starts

## Links

- [Documentation](https://mariadb-operator.github.io/mariadb-operator/latest/)
- [Helm Chart](https://github.com/mariadb-operator/mariadb-operator/tree/main/deploy/charts/mariadb-operator)
- [GitHub Repository](https://github.com/mariadb-operator/mariadb-operator)
