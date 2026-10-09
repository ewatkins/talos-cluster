# [Calagopus](https://calagopus.com) Panel

Game server panel at `https://calagopus.ewatkins.dev`, replacing the
Pterodactyl panel (`default/pterodactyl`). Calagopus is a Rust rewrite of
Pterodactyl that keeps its eggs and Wings API, and ships an importer that
copies a Pterodactyl database across.

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/calagopus/panel:1.2.4` (digest-pinned) |
| Database | `calagopus` on `crunchy-postgres-17`, through pgBouncer |
| Cache | Shared Dragonfly, keys prefixed `calagopus::` |
| File storage | 1 Gi `nfs-fast` PVC at `/var/lib/calagopus` |
| Encryption key | `calagopus-secret` Bitwarden item, `encryption_key` field |
| Wings | Unchanged VMs on VLAN 50; see [WINGS.md](./WINGS.md) |

Only the panel runs in the cluster. Wings drives a Docker daemon directly, and
Talos has none; running it here would mean a privileged Docker-in-Docker pod,
which upstream does not support. The four Wings VMs keep running the game
servers and keep their data where it is.

## Migration plan

The game servers can go down during the migration (no players use them), so
the plan favours stopping things over keeping them live. **Nothing is
deleted** until its replacement has been checked: the Pterodactyl database,
release and Wings VMs all stay intact until the last phase.

### Phase 0: Back up and take inventory

Do all of this before merging this PR.

1. **Back up the Wings VMs** (`wing-proxy` 5000, `wing-node01` 5010,
   `wing-node02` 5020, `wing-node03` 5030) with `vzdump`, then **restore
   one to a spare VMID and check it boots and has its files**. Two of these
   disks sit on `caspian` storage, which has produced zero-filled copies
   that reported success before. A backup that has not been restored is not
   a backup.
2. **Dump the Pterodactyl database and every per-server database** from
   MariaDB and keep the dumps off-cluster:

   ```sh
   kubectl -n database exec mariadb-0 -c mariadb -- sh -c \
     'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --routines --triggers --databases pterodactyl' \
     > pterodactyl-$(date +%F).sql
   # Per-server databases Pterodactyl created (s<id>_<name>):
   kubectl -n database exec mariadb-0 -c mariadb -- sh -c \
     'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -N -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name REGEXP \"^s[0-9]+_\""'
   ```

   Dump each schema the second command lists the same way.
3. **Copy each node's Wings config**, `/etc/pterodactyl/config.yml`, off the VMs.
4. **Take an inventory** to check against after the cutover. On each Wings VM:

   ```sh
   docker ps -a --format '{{.Names}}\t{{.Status}}'          # one per server UUID
   du -sh /var/lib/pterodactyl/volumes/* /var/lib/pterodactyl/backups
   find /var/lib/pterodactyl/volumes -type f | wc -l
   ```

   Also note from the Pterodactyl admin area: users, servers per node,
   allocations per node, database hosts, and the backup driver in use.

### Phase 1: Deploy the panel alongside Pterodactyl

1. **Create two Bitwarden items** before merging:
   - `calagopus-secret`, with field `encryption_key` set to a new random
     value (`openssl rand -base64 32`). Do **not** reuse Pterodactyl's
     `APP_KEY`, and never change this value after the first boot.
   - `calagopus-import-secret`, with field `password` for the read-only
     MariaDB importer account.
2. **Merge this PR.** Flux creates:
   - the `calagopus` user and database on `crunchy-postgres-17`
   - the `calagopus-import` MariaDB account (`SELECT` on `pterodactyl.*` only)
   - the panel
3. **Open `https://calagopus.ewatkins.dev` and stop at the setup (OOBE)
   screen.** Do not create an admin user: the importer expects an empty
   target.

Pterodactyl keeps running untouched through this phase.

### Phase 2: Rehearse the import

The importer reads `/import/ptero.env`, which is mounted from the
`calagopus-import-env` secret. Its database account can only `SELECT`, so the
Pterodactyl database cannot be changed by this step.

```sh
POD=$(kubectl -n default get pod -l app.kubernetes.io/name=calagopus -o name)

# 1. Validate only; writes nothing.
kubectl -n default exec "$POD" -- calagopus-panel import pterodactyl \
  --environment /import/ptero.env --dry-run --on-invalid=abort \
  --report /tmp/import-report.json
kubectl -n default exec "$POD" -- cat /tmp/import-report.json > import-report.json

# 2. If the report is clean (or the fixes are acceptable), import for real.
kubectl -n default exec -it "$POD" -- calagopus-panel import pterodactyl \
  --environment /import/ptero.env
kubectl -n default rollout restart deploy/calagopus
```

Check the rehearsal against the Phase 0 inventory:

- Log in with an existing Pterodactyl account. 2FA, if enabled, still works.
- Users, nodes, servers per node and allocations match.
- **Server UUIDs match** the container names from `docker ps`. Wings finds
  server data by UUID, so this is the check that matters most.
- **Database hosts:** point the imported MariaDB host at
  `mariadb-primary.database.svc.cluster.local` if it shows anything else, and
  attach it to the nodes.
- **Egg configurations:** recreate any that need **User Self Assign**
  allocations, which are not imported.

A rehearsal changes nothing on the Wings side, so the nodes show as offline
here. That is expected.

### Phase 3: Final import and Wings cutover

1. **Stop all game servers** from the Pterodactyl panel, and stop making
   changes there. Anything changed in Pterodactyl after the final import is
   not carried over.
2. **Reset the rehearsal target.** The importer refuses a database that
   already holds data, and a clean import beats `--force`:

   ```sh
   kubectl -n default scale deploy/calagopus --replicas=0
   kubectl -n database exec -it $(kubectl -n database get pod \
     -l postgres-operator.crunchydata.com/cluster=crunchy-postgres-17,postgres-operator.crunchydata.com/role=master -o name) \
     -c database -- psql -c 'DROP DATABASE calagopus WITH (FORCE)' \
     -c 'CREATE DATABASE calagopus OWNER calagopus'
   kubectl -n default scale deploy/calagopus --replicas=1
   ```

   Only drop `calagopus`. Check the command before running it, because the
   same cluster hosts Dispatcharr and AWX.
3. **Run the final import** with the Phase 2 commands, and repeat the checks.
4. **Switch Wings over one node at a time** by following
   [WINGS.md](./WINGS.md). Start with `wing-node03`, then `wing-node02`,
   `wing-node01` and `wing-proxy` last (Velocity sits in front of the others).
5. **Verify each node** in the panel: it shows online, and every server
   starts. Its console, file manager and SFTP work, and a test backup
   succeeds.

### Phase 4: Decommission Pterodactyl

Only after every node has run on Calagopus for a while:

1. Scale Pterodactyl to zero and remove its route, but keep the HelmRelease
   files in Git history so it can be restored.
2. Move the Minecraft Gatus checks (`default/pterodactyl/app/gatus.yaml`)
   into this app.
3. Remove `default/pterodactyl`, the `calagopus-import-env` secret and its
   `/import` mount, and the `calagopus-import` MariaDB user and grant.
4. **Keep the `pterodactyl` MariaDB user** while any per-server database
   still exists. It owns the grants Pterodactyl created, and Calagopus uses
   it as the database host account. Rename it later if you like, but do not
   drop it with the panel.
5. Keep the `pterodactyl` database and the Phase 0 dumps until you are sure
   nothing is missing; they cost almost nothing to keep.

### Rollback

| Point | How to roll back |
| --- | --- |
| Phases 1 and 2 | Nothing to undo; Pterodactyl was never touched. Reset or drop the `calagopus` database if needed. |
| Phase 3, per node | Restore the old Wings binary and `remote:` on that node (see [WINGS.md](./WINGS.md#rollback)). Pterodactyl still holds the node's records. |
| Phase 4 | Revert the removal commit; the `pterodactyl` database is still in MariaDB. |

## Not migrated

- **API keys.** The hashes and the API itself differ from Pterodactyl's.
  Generate new keys and update any scripts that used the old API.
- **Login sessions.** Everyone signs in again.
- **Self-assignable allocations.** These are an egg-configuration setting in
  Calagopus; recreate them after the import.

## Links

- [Calagopus documentation](https://calagopus.com/docs)
- [Migrating from Pterodactyl](https://calagopus.com/docs/additional/migrations/pterodactyl)
- [Panel repository](https://github.com/calagopus/panel)
