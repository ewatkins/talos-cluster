# [RedisInsight](https://github.com/RedisInsight/RedisInsight)

A web-based GUI for exploring and managing Redis-compatible databases. Used to query and inspect the Dragonfly cluster. RedisInsight is compatible with Dragonfly — connect using the standard Redis connection format (`dragonfly.database.svc.cluster.local:6379`).

## Configuration

| Setting | Value |
| --- | --- |
| Chart | `bjw-s/app-template` v3.7.3 |
| Image | `redis/redisinsight:3.2.0` |
| Strategy | Recreate |
| Port | 5540 |
| URL | `https://redis.ewatkins.dev` (internal gateway) |
| CPU request | 15m |
| Memory limit | 204 Mi |
| Logging | stdout only (`RI_STDOUT_LOGGER=true`, `RI_FILES_LOGGER=false`) |
| Security | all capabilities dropped, `allowPrivilegeEscalation: false` |

The Kubernetes Service is named `redisinsight-svc` (not `redisinsight`) to avoid conflicts with the `REDISINSIGHT_HOST` and `REDISINSIGHT_PORT` environment variables that the application reads.

## Links

- [Documentation](https://redis.io/docs/connect/insight/)
- [GitHub Repository](https://github.com/RedisInsight/RedisInsight)
