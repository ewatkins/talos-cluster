# Minio → Garage Migration Runbook

Migration plan for moving object storage off [Minio](../minio/) onto [Garage](./README.md).

## Scope

Loki uses `type: filesystem` (not S3) and Grafana only imports a Minio *dashboard*, so
neither is a consumer. Four consumers are being consolidated onto Garage:

| Consumer | Bucket | Current source | Addressing | Creds secret |
| --- | --- | --- | --- | --- |
| Thanos | `thanos` | Minio `minio.storage.svc.cluster.local:9000` (in-cluster) | path, insecure | `minio-thanos-secret` (accesskey/secretkey) |
| Forgejo | `forgejo` | Minio `s3.ewatkins.dev:443` (gateway) | minio-go SDK | `forgejo-bucket` (MINIO_ACCESS_KEY_ID/SECRET) |
| Crunchy pgBackRest (repo2) | `crunchy-pgo` | Minio `s3.ewatkins.dev` (gateway) | path (`repo2-s3-uri-style: path`) | crunchy externalsecret |
| Outline | `outline` | **iDrive e2** `h4d6.ch.idrivee2-28.com` (region `us-midwest-1`) — *not Minio* | **virtual-hosted** (`AWS_S3_FORCE_PATH_STYLE: "false"`) | `outline-secret` externalsecret |

> **Note:** Outline is already off Minio (it runs on iDrive e2). It is included here to
> consolidate all object storage onto Garage, so its Phase 3 data sync pulls from **iDrive e2**,
> not Minio.

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

## Phase 1 — Provision buckets + keys ✅ COMPLETE

Four buckets created, each with a dedicated RW key:

| Bucket | Key name | Key ID (public) |
| --- | --- | --- |
| `thanos` | `thanos-key` | `GK8954a77e6774242451088383` |
| `forgejo` | `forgejo-key` | `GK2c46cd0def8a3a177df09ff0` |
| `crunchy-pgo` | `crunchy-key` | `GKae42f67abd16ea8ebbb29d02` |
| `outline` | `outline-key` | `GK57319b5e07d7498dea8c1c26` |

Commands used (keys were created by the operator so the secrets never entered the assistant
transcript; permission bindings run by key name):

```bash
/garage bucket create <bucket>
/garage key create <app>-key        # run manually; secret -> Bitwarden
/garage bucket allow --read --write <bucket> --key <app>-key
```

The key secrets were stored as **new fields** in each app's Bitwarden item (e.g.
`garage-accesskey` / `garage-secretkey`), alongside the existing live creds so nothing breaks
before cutover. The configs are re-pointed to the Garage fields in Phase 4.

## Phase 2 — Addressing decision + endpoint verification ✅ COMPLETE

**Decision: path-style** — so **no wildcard DNS/TLS work is needed** (the alternative would
have been a `*.s3-garage.ewatkins.dev` record + TLS SAN for virtual-hosted access). Outline
currently uses virtual-hosted (`AWS_S3_FORCE_PATH_STYLE: "false"`); it will switch to path-style
against Garage's flat `s3-garage.ewatkins.dev` endpoint.

The `AWS_S3_FORCE_PATH_STYLE: "true"` flip in
[outline/app/helmrelease.yaml](../../default/outline/app/helmrelease.yaml) is **deferred to the
Phase 4 Outline cutover**, done atomically with the endpoint/creds swap — flipping it early
would switch the still-live iDrive e2 connection to path-style (unverified there) for no gain.

Garage's gateway S3 endpoint (`s3-garage.ewatkins.dev` → `garage-api:3900`) was verified:

- `GET https://s3-garage.ewatkins.dev/` → HTTP 403 (as Gatus expects).
- `GET https://s3-garage.ewatkins.dev/thanos/` → Garage S3 XML `AccessDenied` naming the
  `thanos` bucket and region `us-east-1` — confirms the gateway route reaches the Garage S3 API
  and **path-style addressing resolves correctly**. This is the endpoint Forgejo, Crunchy, and
  Outline use at cutover (Thanos uses the in-cluster `garage.storage.svc.cluster.local:3900`).

## Phase 3 — Copy data (source stays live) ✅ COMPLETE (initial bulk sync)

Tooling: `rclone` (added to the workstation [Brewfile](../../../../.taskfiles/Workstation/Brewfile)
and [Archfile](../../../../.taskfiles/Workstation/Archfile)). Run from the workstation, which
can reach `s3.ewatkins.dev`, `s3-garage.ewatkins.dev`, and iDrive e2.

**Remote layout:** each Garage key is scoped to a single bucket, so a single `garage:` remote
can't reach all four — use **one Garage remote per bucket** (`garage-thanos`, `garage-forgejo`,
`garage-crunchy`, `garage-outline`), each with that bucket's existing key. Sources: `minio`
(root creds; reads thanos/forgejo/crunchy-pgo) and `idrive` (outline-secret creds; reads
outline). Garage remotes use `provider = Other` + explicit `endpoint` → rclone auto-uses
path-style. The `rclone.conf` holds secrets, so it lives only on the workstation (not in Git).

```bash
rclone sync minio:thanos       garage-thanos:thanos        --progress --transfers 8
rclone sync minio:forgejo      garage-forgejo:forgejo      --progress --transfers 8
rclone sync minio:crunchy-pgo  garage-crunchy:crunchy-pgo  --progress --transfers 8
rclone sync idrive:outline     garage-outline:outline      --progress --transfers 8
```

**Verification results (initial sync):**

| Bucket | Result |
| --- | --- |
| `thanos` | 83 objects / 12.506 GiB — matched after a delta sync |
| `forgejo` | 11 objects — byte-identical |
| `crunchy-pgo` | 25,328 files — `rclone check` **0 differences** after a delta sync |
| `outline` | 4 objects — byte-identical (iDrive e2 → Garage) |

**Notes / lessons:**

- `rclone check` reports "N hashes could not be checked" — **normal**; Garage returns non-MD5
  ETags for multipart uploads, so rclone falls back to size comparison.
- `thanos` and `crunchy-pgo` are **continuously written** (Thanos ships TSDB blocks; pgBackRest
  archives WAL), so they drift by a few objects between sync and check. Re-running that bucket's
  `rclone sync` clears it. Each needs a **final delta sync at its cutover** (Phase 4).
- `forgejo` and `outline` are static — fully done, no further sync needed before cutover.

## Phase 4 — Cut over one consumer at a time (low-risk first)

**Credential approach:** the Garage key/secret were added as **new fields** in each app's
existing Bitwarden item, and each app's **ExternalSecret is re-pointed** to read those fields
(the live Minio/iDrive fields are left in place for rollback; Bitwarden cleanup happens later).
Output secret keys are also renamed off `MINIO_*` where the consumer allows.

1. **Forgejo** ✅ **DONE** — [helmrelease.yaml](../../development/forgejo/app/helmrelease.yaml)
   + [externalsecret.yaml](../../development/forgejo/app/externalsecret.yaml):
   - `MINIO_ENDPOINT: s3-garage.ewatkins.dev:443`
   - `MINIO_BUCKET_LOOKUP: path` — **required**: Forgejo uses the minio-go client, whose
     auto-detection could pick virtual-host (`forgejo.s3-garage…`, no wildcard DNS). Pin `path`.
   - ExternalSecret `forgejo-bucket` output keys renamed `MINIO_ACCESS_KEY_ID`/`_SECRET_` →
     `access-key-id`/`secret-access-key`, sourced from Bitwarden `garage-access-key-id` /
     `garage-secret-access-key`; helmrelease `valuesFrom.valuesKey` updated to match
     (`targetPath` keeps Forgejo's `gitea.config.storage.MINIO_*` schema — unavoidable).
   - Verified: all 7 storage backends init against Garage with no errors. Final human smoke
     test: upload an avatar/attachment, confirm the object lands in `garage-forgejo:forgejo`.
2. **Thanos** — in [thanos/app/helmrelease.yaml](../../observability/thanos/app/helmrelease.yaml)
   set `endpoint: garage.storage.svc.cluster.local:3900` (keep `insecure: true`,
   `region: us-east-1`); re-point `minio-thanos-secret` ExternalSecret to the Garage fields. Also
   repoint the Flux [Bucket](../../observability/thanos/app/bucket.yaml) source and change its
   `dependsOn: minio` → `garage`. Final `rclone sync minio:thanos …` first. Verify queries +
   a compaction cycle.
3. **Outline** ✅ **DONE** — [helmrelease.yaml](../../default/outline/app/helmrelease.yaml)
   + [externalsecret.yaml](../../default/outline/app/externalsecret.yaml):
   - `AWS_S3_FORCE_PATH_STYLE: "true"` (path-style, from Phase 2).
   - ExternalSecret creds re-pointed to Bitwarden `garage-access-key-id` /
     `garage-secret-access-key`; non-secret `AWS_S3_UPLOAD_BUCKET_URL` /`AWS_REGION` hardcoded to
     `https://s3-garage.ewatkins.dev` / `us-east-1` (moved off iDrive e2's values). iDrive creds
     kept in the Bitwarden item for rollback. Output keys are Outline's `AWS_*` env schema
     (no `MINIO_` naming to remove).
   - **CORS is required** (see below) — Outline uploads go *browser → S3 directly* via a
     presigned URL, so the bucket needs a CORS rule or uploads fail with **no server-side error**
     in Outline's logs (the failure is browser↔Garage).
   - Verified: ES synced with correct Garage cred lengths; image upload + existing-image read
     both confirmed against `garage-outline:outline`.

### Garage bucket CORS (imperative — NOT in Git)

Garage has no CORS CRD or CLI subcommand; CORS is set via the S3 `PutBucketCors` API and stored
in Garage's bucket metadata (persists across restarts, but **would be lost if the bucket is
recreated**). Any bucket serving **browser-direct uploads** needs this. The key must hold
`owner` permission to set it:

```bash
# grant owner (one-time; RW alone cannot set bucket config)
kubectl -n storage exec garage-0 -c app -- /garage bucket allow --owner outline --key outline-key

# set the CORS rule (aws-cli; creds = that bucket's Garage key)
aws s3api put-bucket-cors \
  --endpoint-url https://s3-garage.ewatkins.dev --region us-east-1 --bucket outline \
  --cors-configuration '{"CORSRules":[{
    "AllowedOrigins":["https://notes.ewatkins.dev"],
    "AllowedMethods":["GET","PUT","POST","HEAD","DELETE"],
    "AllowedHeaders":["*"],"ExposeHeaders":["ETag"],"MaxAgeSeconds":3000}]}'

# verify: expect HTTP 200 + access-control-allow-origin/-methods
curl -sk -X OPTIONS https://s3-garage.ewatkins.dev/outline/x -D - -o /dev/null \
  -H 'Origin: https://notes.ewatkins.dev' -H 'Access-Control-Request-Method: PUT' | grep -i access-control
```

> Forgejo/Thanos/pgBackRest do **not** need CORS — they talk to S3 server-side, not from a
> browser.
4. **Crunchy pgBackRest (last — most critical)** — in
   [crunchy .../cluster.yaml](../../database/crunchy-postgres-operator/cluster/cluster.yaml)
   set repo2 `endpoint: s3-garage.ewatkins.dev` (keep `repo2-s3-uri-style: path`); new creds.
   Then **run a full backup and a test restore** before trusting it.

After each cutover, watch the app + its Gatus check for a full cycle before moving on.

## Phase 5 — Decommission old storage

Once all four are verified (give Thanos/pgBackRest a few days of successful backup cycles):

- Remove the old creds from each app's Bitwarden item (Minio for Thanos/Forgejo/Crunchy,
  iDrive e2 for Outline).
- Delete `kubernetes/apps/storage/minio/` and its entry in
  [storage/kustomization.yaml](../kustomization.yaml).
- Retain the `minio-data` PVC briefly as a safety net, then reclaim.
- For Outline: once verified on Garage, cancel/clean up the external **iDrive e2** bucket.

## Rollback

Until Phase 5, rollback for any consumer is: revert its endpoint/creds change in Git and
reconcile — the original source still holds the data (Minio for Thanos/Forgejo/Crunchy, iDrive
e2 for Outline). That is why the old sources stay fully live through Phase 4.
