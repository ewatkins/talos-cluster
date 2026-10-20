# [Calagopus](https://calagopus.com) Panel

Game server panel at `https://mcpanel.ewatkins.dev`, replacing the
Pterodactyl panel (`default/pterodactyl`). Calagopus is a Rust rewrite of
Pterodactyl that keeps its eggs and Wings API, and ships an importer that
copies a Pterodactyl database across.

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/calagopus/panel:1.2.6-heavy` (digest-pinned); the heavy variant can build extensions |
| Database | `calagopus` on `crunchy-postgres-17`, through pgBouncer |
| Cache | Shared Dragonfly, keys prefixed `calagopus::` |
| File storage | 1 Gi `nfs-fast` PVC at `/var/lib/calagopus` |
| Extension builds | 5 Gi `nfs-fast` PVC `calagopus-build`, mounted at `/app/binaries`, `/app/translations`, `/app/extensions` and `/app/repo/database/extension-migrations` |
| Encryption key | `calagopus-secret` Bitwarden item, `encryption_key` field |
| Wings | One VM per world on VLAN 50, named after it, defined in [`terraform/wings`](../../../../terraform/wings/README.md) and built by tofu-controller from [`wings/`](./wings/terraform.yaml) (Flux Kustomization `calagopus-wings`); see [WINGS.md](./WINGS.md) |

Only the panel runs in the cluster. Wings drives a Docker daemon directly, and
Talos has none; running it here would mean a privileged Docker-in-Docker pod,
which upstream does not support. The game servers move from the four
Pterodactyl Wings VMs to new Calagopus Wings VMs (one per world),
which take over the old addresses.

## Extensions

The panel runs the **heavy** image, which ships the Rust and Node toolchains so
it can recompile itself with extensions
([Calagopus docs](https://calagopus.com/docs/panel/extensions/switching-to-the-heavy-image)).
Install an extension by uploading its `.c7s.zip` in the admin area's
extension page; the build runs in the background and the panel restarts on the
new binary when it finishes. Builds are cached in `calagopus-build`, so a pod
restart reuses the last one.

A build needs far more memory than the panel itself, so the container's limit
is 6 Gi (three parallel build jobs). If builds are killed for running out of
memory, raise it.

To go back to the regular image, change the tag back (`1.2.6-heavy` →
`1.2.6`). The regular image ignores the build volume, and the extension
archives stay in it for a later switch back.

## Single sign-on (Keycloak)

Calagopus keeps OAuth providers in its database, not in its environment, so
this is set up in the admin area rather than in Git. The provider's client
secret is stored encrypted with `APP_ENCRYPTION_KEY`.

| Setting | Value |
| --- | --- |
| Client ID | `calagopus` (confidential) |
| Auth URL | `https://keycloak.ewatkins.dev/realms/master/protocol/openid-connect/auth` |
| Token URL | `https://keycloak.ewatkins.dev/realms/master/protocol/openid-connect/token` |
| Info URL | `https://keycloak.ewatkins.dev/realms/master/protocol/openid-connect/userinfo` |
| Scopes | `openid`, `email`, `profile` |
| Identifier path | `$.sub` |
| Email path | `$.email` |
| Username path | `$.preferred_username` |
| First / last name paths | `$.given_name` / `$.family_name` |
| PKCE | On |
| Login only | On: a Keycloak login must already be linked to a panel account |
| Redirect URI | `https://mcpanel.ewatkins.dev/api/auth/oauth/<provider UUID>` |

**Import from OpenID Discovery** in the create form does not work here: in
the cluster `keycloak.ewatkins.dev` resolves to the external gateway
(`192.168.40.30`), and the panel refuses to fetch user-supplied URLs on
private addresses (`APP_BLOCKED_CIDRS`). Enter the endpoints by hand instead.
Only the discovery import goes through that check; sign-in requests to the
token and info URLs do not.

The redirect URI ends in the provider's UUID, which Calagopus assigns when the
provider is created, so the provider comes first:

1. **Check the panel URL.** In **Admin → Settings**, the app URL must be
   `https://mcpanel.ewatkins.dev`; Calagopus builds the redirect URI from it.
2. **Create the provider, disabled.** In **Admin → OAuth Providers →
   Create**, name it `Keycloak`, fill in the settings above, and leave it
   disabled. Save it; the provider's page then shows its redirect URL.
3. **Create the Keycloak client.** In the `master` realm: **Clients → Create
   client → OpenID Connect**, client ID `calagopus`, **Client
   authentication** on. Set **Valid redirect URIs** to the redirect URL the
   provider's page shows; it must match exactly. Copy the secret from the
   **Credentials** tab.
4. **Finish the provider.** Paste the secret into the provider, enable it and
   save.
5. **Link accounts.** Each user signs in with their password once, then
   links Keycloak under **Account → OAuth Links**. An admin can also link a
   user from **Admin → Users**.

**Login only** stays on because Keycloak signs people in with GitHub and
Google: with it off, any Keycloak login with no linked account would create a
new panel account. Leave **Bypass two-factor** off unless Keycloak enforces
its own second factor.

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
3. **Open `https://mcpanel.ewatkins.dev` and stop at the setup (OOBE)
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
4. **Move each node to its new VM, one at a time**, by following
   [WINGS.md](./WINGS.md): `wing-node03` → `wing-atlas`, `wing-node02` →
   `wing-iridium`, `wing-node01` → `wing-homestead`, and `wing-proxy` last
   (Velocity sits in front of the others).
5. **Verify each node** in the panel: it shows online, and every server
   starts. Its console, file manager and SFTP work, and a test backup
   succeeds.

### Phase 4: Decommission Pterodactyl (2026-10-15)

1. Removed `default/pterodactyl` (it is in Git history if it is ever needed),
   the `calagopus-import-env` secret and its `/import` mount, and the
   `calagopus-import` MariaDB user and grant.
2. Moved the Minecraft Gatus checks into this app (`app/gatus.yaml`).
3. Gave the database host its own MariaDB account, `calagopus`. No server
   databases existed, so the `pterodactyl` account owned none. In the panel,
   **Admin → Database Hosts → Cluster MariaDB**, set the username to
   `calagopus` and the password from
   `kubectl -n database get secret calagopus-dbhost-secret -o jsonpath='{.data.password}' | base64 -d`.
4. Removed the `pterodactyl` MariaDB user, grant and database objects once
   the database host tested successfully with `pterodactyl` locked, then
   dropped the schema by hand. A final dump is in
   `~/backups/pterodactyl-migration-2026-10-13/`, alongside the Phase 0
   dumps.
5. Moved the wings themselves to Calagopus's names (see [WINGS.md](./WINGS.md)).
6. In **Admin → Settings → Mail**, the sender still reads Pterodactyl:
   rename it.

### Rollback

| Point | How to roll back |
| --- | --- |
| Phases 1 and 2 | Nothing to undo; Pterodactyl was never touched. Reset or drop the `calagopus` database if needed. |
| Phase 3, per node | Power off the new VM and power the old one back on (see [WINGS.md](./WINGS.md#rollback)). The old VM is never modified, and Pterodactyl still holds the node's records. |
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
