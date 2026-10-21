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
3. Pair the wing. The node's token comes from the panel's CLI and goes
   straight into Wings' join data, so it is never shown:

   ```sh
   kubectl -n calagopus-test exec deploy/calagopus-test -- \
     panel-rs nodes reset-token --node wing-test --json 2>&1 >/dev/null \
   | python3 -c 'import json,sys,base64; t=sys.stdin.read(); d=json.loads(t[t.index("{"):t.rindex("}")+1]); print(base64.b64encode(json.dumps({**d, "api": {"port": 8080}, "system": {"sftp": {"bind_port": 2022}}, "remote": "https://mcpanel-test.ewatkins.dev"}).encode()).decode())' \
   | ssh ewatkins@192.168.50.40 'read -r jd; sudo wings configure --join-data "$jd" && sudo systemctl start wings'
   ```

   Wings serves plain HTTP here (`api.ssl.enabled: false`, the default for
   join data); only the panel talks to it.

### Network

Browsers never reach the wing: the node's public URL is the panel's Wings
proxy (`https://mcpanel-test.ewatkins.dev/wings-proxy/<node uuid>`, set by
the seed Job), so the console and file transfers go through the panel. The
UniFi policies for VLAN 50 allow by address, so 192.168.50.40 is listed in:

| Policy | For |
| --- | --- |
| MC: cluster to Wings API and BlueMap | the panel to Wings (8080) |
| MC: Wings to panel | Wings to `mcpanel-test` through Envoy (443) |
| MC: tailnet SSH and SFTP | SSH and SFTP over Tailscale (22, 2022) |

It is not in **MC: cluster and tailnet to game ports**: test servers are
reachable from the management VLAN only. These policies live in UniFi, not
in Git.

## Installing an extension

Upload the `.c7s.zip` in **Admin > Extensions**. The panel rebuilds itself
(about a minute) and restarts onto the new binary.

## Resetting

- **Panel only:** delete the namespace; Flux recreates it and the seed Job
  skips everything that already exists.
- **Everything:** also drop and recreate the database (remove the user from
  `crunchy-postgres-17`, merge, add it back), then pair the wing again.
