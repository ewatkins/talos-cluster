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

## Phase 0 — Stand up Garage correctly (blocker)

1. **Resolve the topology contradiction.** The [helmrelease](./app/helmrelease.yaml) is a
   **3-replica StatefulSet** with `replication_factor = 3` in
   [configuration.toml](./app/resources/configuration.toml), but the [README](./README.md)
   describes a single-node/rf-1 deployment. Manifests are the source of truth — update the
   README to describe the 3-node cluster (rf 3).
2. Deploy Garage, then verify the cluster forms — all three nodes must be connected:

   ```bash
   kubectl -n storage exec garage-0 -c app -- /garage status   # expect garage-0/1/2
   ```

   The hardcoded `bootstrap_peers` node IDs in `configuration.toml` must match the nodes'
   actual identities. If `status` shows fewer than 3 nodes, that mismatch is the cause.
3. Apply the storage layout (required before any write works with rf 3):

   ```bash
   # for each of the 3 node IDs from `garage status`
   /garage layout assign -z dc1 -c 20G <node-id>
   /garage layout apply --version 1
   ```
4. Confirm `garage status` shows all nodes with role/capacity assigned.

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
