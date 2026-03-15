# Storage

Storage infrastructure including the default local PV provisioner (OpenEBS), NFS CSI driver, and S3-compatible object stores.

## Apps

| App | Description |
| --- | --- |
| [csi-driver-nfs](csi-driver-nfs/README.md) | CSI driver provisioning NFS-backed PersistentVolumes from the `caspian.local` NAS |
| [garage](garage/README.md) | Lightweight distributed S3-compatible object store (Garage v2) with a web management UI protected by Keycloak OIDC |
| [minio](minio/README.md) | S3-compatible object storage used by Thanos (metrics), Loki (logs), and Forgejo (attachments) |
| [openebs](openebs/README.md) | Default `hostpath` PersistentVolume provisioner for node-local fast storage |
