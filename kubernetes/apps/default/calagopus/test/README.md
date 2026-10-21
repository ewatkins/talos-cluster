# Calagopus test panel

A second, throwaway Calagopus panel for developing extensions (Anvil) without
touching the production panel. It runs the same image as `../app`, at
<https://mcpanel-test.ewatkins.dev> (internal gateway only), with one wing:
`wing-test` (192.168.50.40, `test` in [`terraform/wings`](../../../../../terraform/wings/main.tf)).

## What persists

| Piece | Where | Survives deleting the namespace |
| --- | --- | --- |
| Panel data (users, nodes, servers, settings) | `calagopus-test` database in `crunchy-postgres-17` | Yes |
| Encryption key, admin login | Bitwarden item `calagopus-test-secret` | Yes |
| Compiled binaries, uploaded extensions | `calagopus-test-build` PVC (`nfs-fast`) | No: re-upload the extension |
| Cache | Dragonfly, prefix `calagopus-test` | Not needed |
| Wing pairing | `/etc/calagopus-wings/config.yml` on the VM | Yes |

First-run setup is done by the [seed Job](./seed.yaml), not the setup wizard:
admin user, panel URL and name, sign-ups and telemetry off, the `Test`
location and the `wing-test` node. It is idempotent and runs again whenever
the Job changes.

## One-time setup

1. Create the Bitwarden item `calagopus-test-secret` with the fields
   `encryption_key` (`openssl rand -base64 32`, never change it afterwards),
   `admin_email` and `admin_password`.
2. Merge. Flux creates the database user, the panel and the seed Job; the
   test wing is built by tofu-controller from the same merge.
3. Pair the wing: in the panel, **Admin > Nodes > wing-test**, copy the
   enrollment code, then run it on the wing and start Wings. The panel shows
   the command as `calagopus-wings`; cloud-init installs the binary as
   `wings`:

   ```sh
   ssh ewatkins@192.168.50.40
   sudo wings configure --panel-url https://mcpanel-test.ewatkins.dev --enroll <code>
   # Plain HTTP: only the panel talks to this wing (APP_ENABLE_WINGS_PROXY),
   # and the node's URL is http://192.168.50.40:8080.
   sudoedit /etc/calagopus-wings/config.yml   # api.ssl.enabled: false
   sudo systemctl start wings
   ```

   **Verify Connection** on the node page must pass.

## Installing an extension

Upload the `.c7s.zip` in **Admin > Extensions**. The panel rebuilds itself
(about a minute) and restarts onto the new binary.

## Resetting

- **Panel only:** delete the namespace; Flux recreates it and the seed Job
  skips everything that already exists.
- **Everything:** also drop and recreate the database (remove the user from
  `crunchy-postgres-17`, merge, add it back), then pair the wing again.
