# [Dragonfly](https://www.dragonflydb.io/)

A high-performance, Redis-compatible in-memory data store. Deployed via the Dragonfly Operator and used as a drop-in Redis replacement for application caching and session storage.

## Operator Configuration

| Setting | Value |
| --- | --- |
| Chart | `bjw-s/app-template` v3.7.3 |
| Image | `ghcr.io/dragonflydb/operator:v1.4.0` |
| Strategy | RollingUpdate |
| Metrics port | 8080 |
| Health probe port | 8081 |
| CPU request | 15m |
| Memory limit | 105 Mi |
| Security | non-root (UID/GID 65534), `readOnlyRootFilesystem`, all capabilities dropped |

The operator has a ClusterRole with permissions to manage `Dragonfly` CRs, StatefulSets, Services, PodDisruptionBudgets, and Leases.

## Cluster Configuration

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/dragonflydb/dragonfly:v1.37.0` |
| Replicas | 3 |
| Memory limit | 512 Mi |
| CPU request | 35m |
| Memory request | 105 Mi |
| Cluster mode | emulated |
| Proactor threads | 2 |
| `max_memory` | dynamically set from `limits.memory` |
| Topology spread | One pod per node (`kubernetes.io/hostname`), `DoNotSchedule` |
| Service address | `dragonfly.database.svc.cluster.local:6379` |

## Monitoring and Health

- PodMonitor scrapes the `admin` port on pods labelled `app: dragonfly`.
- Gatus health check: TCP connect to `dragonfly.database.svc.cluster.local:6379` every 1 minute, with Pushover alerting on failure.

## Links

- [Documentation](https://www.dragonflydb.io/docs)
- [GitHub Repository](https://github.com/dragonflydb/dragonfly)
- [Operator GitHub](https://github.com/dragonflydb/dragonfly-operator)
