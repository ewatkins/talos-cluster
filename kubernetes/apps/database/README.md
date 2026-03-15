# Database

Database operators, clusters, and management tools that back applications across the cluster. All resources deploy into the `database` namespace.

Flux HelmRelease errors are forwarded to Alertmanager at `http://alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [crunchy-postgres-operator](crunchy-postgres-operator/README.md) | PGO operator (v6.0.0) managing two HA PostgreSQL 16 clusters: a general-purpose 3-replica cluster with PgBouncer and pgBackRest backups to NFS/Minio/R2, and a VectorChord-enabled cluster for Immich |
| [dragonfly](dragonfly/README.md) | Redis-compatible in-memory store — 3-replica Dragonfly cluster (`v1.37.0`, 512 Mi limit) managed by the Dragonfly Operator, used for application caching and session state |
| [mariadb](mariadb/README.md) | 3-node Galera MariaDB cluster with MaxScale proxy, managed by the MariaDB Operator; hosts databases for Minecraft plugins and Pterodactyl |
| [redisinsight](redisinsight/README.md) | Web GUI (`redis/redisinsight:3.2.0`) for inspecting and querying the Dragonfly cluster at `https://redis.ewatkins.dev` |
