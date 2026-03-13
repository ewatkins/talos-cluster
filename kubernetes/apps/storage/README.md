# storage

This namespace hosts storage infrastructure components including the default local storage provisioner (OpenEBS), NFS CSI driver, and S3-compatible object stores (Minio and Garage).

## Apps

- [csi-driver-nfs](csi-driver-nfs/README.md) - CSI driver for NFS-backed PersistentVolumes
- [garage](garage/README.md) - Lightweight, distributed S3-compatible object store
- [minio](minio/README.md) - S3-compatible object storage used by Thanos, Loki, and other apps
- [openebs](openebs/README.md) - Default local hostpath PersistentVolume provisioner
