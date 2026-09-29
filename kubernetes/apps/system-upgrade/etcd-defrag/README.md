# etcd-defrag

Monthly CronJob that defragments each etcd member in turn (superior, michigan, huron) with `talosctl etcd defrag`, then prints `talosctl etcd status`.

etcd keeps its database file at its high-water mark: compaction frees space inside the file but never returns it to disk. Once less than half of the file is in use, `etcdDatabaseHighFragmentationRatio` fires. Defragmenting rewrites the file down to what is actually in use.

## Access

The Job authenticates with a Talos `ServiceAccount` holding `os:operator`, the smallest role that may defragment. That depends on `talos/talconfig.yaml` allowing both the `os:operator` role and the `system-upgrade` namespace under `kubernetesTalosAPIAccess`.

## Running it by hand

```sh
kubectl -n system-upgrade create job --from=cronjob/etcd-defrag etcd-defrag-manual
kubectl -n system-upgrade logs job/etcd-defrag-manual -c status
```

A failed step stops the Job (`backoffLimit: 0`); check that member with `talosctl etcd status` before re-running.
