# [Garage](https://garagehq.deuxfleurs.fr/)

Garage is a lightweight, distributed S3-compatible object store. It serves as an alternative to Minio for certain workloads and exposes a web management UI for bucket and key administration.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| S3 API endpoint | `https://s3-garage.ewatkins.dev` (port 3900) | S3-compatible API for client access |
| Admin API | Port 3903 | Internal admin endpoint for cluster operations |
| Web UI | `https://garage.ewatkins.dev` | Management interface via Envoy Gateway HTTPRoute |
| Config | `garage-configmap` | Garage node configuration (replication factor, metadata dir, etc.) |
| Credentials | `garage-secret` | Admin and access key credentials |
| Data PVC | `garage-data` | Stores object data blocks |
| Metadata PVC | `garage-meta` | Stores bucket and object metadata |

## Links

- [Documentation](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
- [GitHub Repository](https://git.deuxfleurs.fr/Deuxfleurs/garage)
