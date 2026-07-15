# Minio → Garage Migration Runbook

Migration plan for moving object storage off [Minio](../minio/) onto [Garage](./README.md).

## Scope

Loki uses `type: filesystem` (not S3) and Grafana only imports a Minio *dashboard*, so
neither is a consumer. The real S3 consumers are **four**:

| Consumer | Bucket | Endpoint used | Addressing | Creds secret |
| --- | --- | --- | --- | --- |
| Thanos | `thanos` | `minio.storage.svc.cluster.local:9000` (in-cluster) | path, insecure | `minio-thanos-secret` (accesskey/secretkey) |
| Forgejo | `forgejo` | `s3.ewatkins.dev:443` (gateway) | minio-go SDK | `forgejo-bucket` (MINIO_ACCESS_KEY_ID/SECRET) |
| Outline | `AWS_S3_BUCKET` | gateway | **virtual-hosted** (`AWS_S3_FORCE_PATH_STYLE: "false"`) | outline externalsecret |
| Crunchy pgBackRest (repo2) | `crunchy-pgo` | `s3.ewatkins.dev` (gateway) | path (`repo2-s3-uri-style: path`) | crunchy externalsecret |

**Garage targets:** in-cluster `garage.storage.svc.cluster.local:3900`, gateway
`s3-garage.ewatkins.dev`, region `us-east-1`.

Garage admin commands run via the pod, e.g.:

```bash
kubectl -n storage exec garage-0 -c app -- /garage <command>
```

---

## Phase 0 — Stand up Garage correctly ✅ COMPLETE

Garage was already deployed as a 3-node StatefulSet (`garage-0/1/2`, `dxflrs/garage:v2.3.0`,
`replication_factor = 3`), but a health check found the cluster **degraded** and the
[README](./README.md) stale. Both were fixed.

### What was wrong

- **Ghost node in the layout.** Layout v1 assigned a role to node `1b2e500a…`, an identity
  that was **never a running node** (`FAILED NODES / never seen`).
- **Real garage-1 had no role.** Its metadata PVC had been recreated ~4 days prior, so it came
  up with a *new* identity `0c97bad9…` and showed `NO ROLE ASSIGNED` — connected but storing
  nothing. Net effect: rf 3 but only **2 of 3** nodes actually held data.
- **Stale `bootstrap_peers`.** [configuration.toml](./app/resources/configuration.toml) still
  listed garage-1's dead `1b2e500a…` identity.
- **Stale README.** Claimed single-node / rf 1 / `v2.2.0` / 20Gi-`nfs-slow` data PVCs.

### What was done

```bash
# 1. Re-point garage-1 to its real identity, drop the ghost, apply as layout v2
kubectl -n storage exec garage-0 -c app -- /garage layout assign 0c97bad959a5f39a -z dc1 -c 10G
kubectl -n storage exec garage-0 -c app -- /garage layout remove 1b2e500a571e2501
kubectl -n storage exec garage-0 -c app -- /garage layout apply --version 2

# 2. Retire the old draining layout that was stuck on the (dead) ghost node
kubectl -n storage exec garage-0 -c app -- /garage layout skip-dead-nodes --version 2
```

- Replaced the stale `bootstrap_peers` entry in `configuration.toml`
  (`1b2e500a…` → `0c97bad9…`).
- Corrected the README to the real topology (3-node / rf 3 / `v2.3.0` / 10Gi-`openebs-hostpath`).

### End state

`garage status` shows **3 HEALTHY nodes** (garage-0/1/2), no FAILED nodes, single live layout
version **#2**, 256 partitions per node at 3× replication. No buckets or keys existed yet, so
Phase 1 starts from a clean slate.

> **Gotcha for future node rebuilds:** wiping a Garage node's metadata PVC gives it a **new
> node identity**. After any such rebuild, update `bootstrap_peers` and re-run
> `layout assign` / `layout remove` for the changed ID, or the node will sit roleless.

## Phase 1 — Provision buckets + keys

For each bucket (`thanos`, `forgejo`, `crunchy-pgo`, and Outline's bucket):

```bash
/garage bucket create <bucket>
/garage key create <app>-key
/garage bucket allow --read --write <bucket> --key <app>-key
```

Store each key's ID/secret in the corresponding **Bitwarden Secrets Manager** item (the same
item its ExternalSecret extracts from). Keep the Minio creds in those items until cutover so
nothing breaks mid-flight.

## Phase 2 — DNS/TLS for virtual-hosted access (Outline only)

Outline sets `AWS_S3_FORCE_PATH_STYLE: "false"`, so it addresses buckets as
`<bucket>.s3-garage.ewatkins.dev`. Two options:

- **(a)** Add a wildcard `*.s3-garage.ewatkins.dev` DNS record + gateway route + TLS SAN
  matching Garage's `root_domain`.
- **(b) Preferred:** set `AWS_S3_FORCE_PATH_STYLE: "true"` in
  [outline/app/helmrelease.yaml](../../default/outline/app/helmrelease.yaml) and point it at
  the flat `s3-garage.ewatkins.dev` endpoint — avoids the wildcard-cert hassle.

## Phase 3 — Copy data (Minio still live)

Per bucket, using `rclone` with `minio:` and `garage:` remotes:

```bash
rclone sync minio:thanos      garage:thanos      --progress
rclone sync minio:forgejo     garage:forgejo     --progress
rclone sync minio:crunchy-pgo garage:crunchy-pgo --progress
rclone sync minio:<outline>   garage:<outline>   --progress
```

Thanos/pgBackRest buckets can be large — run an initial sync, then a final delta sync
immediately before each cutover.

## Phase 4 — Cut over one consumer at a time (low-risk first)

1. **Thanos** — in [thanos/app/helmrelease.yaml](../../observability/thanos/app/helmrelease.yaml)
   set `endpoint: garage.storage.svc.cluster.local:3900` (keep `insecure: true`,
   `region: us-east-1`); update `minio-thanos-secret` Bitwarden item to the Garage key. Also
   repoint the Flux [Bucket](../../observability/thanos/app/bucket.yaml) source and change its
   `dependsOn: minio` → `garage`. Verify queries + a compaction cycle.
2. **Forgejo** — in [forgejo/app/helmrelease.yaml](../../development/forgejo/app/helmrelease.yaml)
   set `MINIO_ENDPOINT: s3-garage.ewatkins.dev:443`; update `forgejo-bucket` Bitwarden creds.
   Verify avatar/attachment/LFS read+write.
3. **Outline** — apply the Phase 2 path-style change + new creds. Verify document
   upload/download.
4. **Crunchy pgBackRest (last — most critical)** — in
   [crunchy .../cluster.yaml](../../database/crunchy-postgres-operator/cluster/cluster.yaml)
   set repo2 `endpoint: s3-garage.ewatkins.dev` (keep `repo2-s3-uri-style: path`); new creds.
   Then **run a full backup and a test restore** before trusting it.

After each cutover, watch the app + its Gatus check for a full cycle before moving on.

## Phase 5 — Decommission Minio

Once all four are verified (give Thanos/pgBackRest a few days of successful backup cycles):

- Remove the Minio creds from each app's Bitwarden item.
- Delete `kubernetes/apps/storage/minio/` and its entry in
  [storage/kustomization.yaml](../kustomization.yaml).
- Retain the `minio-data` PVC briefly as a safety net, then reclaim.

## Rollback

Until Phase 5, rollback for any consumer is: revert its endpoint/creds change in Git and
reconcile — Minio still holds the data. That is why Minio stays fully live through Phase 4.
