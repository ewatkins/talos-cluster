# system-upgrade

Automated Talos Linux and Kubernetes version upgrades, and routine node maintenance, for the cluster.

## Apps

| App | Description |
| --- | --- |
| [etcd-defrag](etcd-defrag/README.md) | Monthly CronJob that defragments each etcd member in turn to keep the database file compact |
| [tuppr](tuppr/README.md) | Upgrade controller that performs sequential, rolling Talos OS and Kubernetes version upgrades across all cluster nodes |
