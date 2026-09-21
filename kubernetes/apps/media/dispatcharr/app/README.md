# Dispatcharr

IPTV channel manager. Runs in modular mode: Postgres (Crunchy pg17) and Redis (Dragonfly
db5) are external and Celery runs as its own container.

The pod also hosts **three of the companion tools**. See
[Co-located tools](#co-located-tools).

| | |
| --- | --- |
| URL | `https://dispatcharr.ewatkins.dev` |
| LAN address | `http://192.168.40.101:9191` (XC clients with no working DNS) |
| Companion tools | [`../tools/README.md`](../tools/README.md) |

## No VPN

This pod previously egressed through a [gluetun](https://github.com/qdm12/gluetun) native
sidecar on a Privado OpenVPN tunnel pinned to six London exits, with a `vpn-ui` container at
`gluetun.ewatkins.dev` for rotating the exit. All of it — sidecar, UI, the
`dispatcharr-vpn-server` ConfigMap, the `gluetun-secret` ExternalSecret, the OIDC
SecurityPolicy and the route — has been removed.

**Dispatcharr, Celery and the three co-located tools now egress from the node's own WAN
address.** M3U/EPG fetches and client stream proxying are no longer geolocated to the UK, so
any source that was reachable only through a UK exit will start failing. The pod also no
longer needs `NET_ADMIN`, and there is no longer a kill switch or a single tunnel that can
take the whole pod down with it.

Two things outside this repo are now orphaned and can be cleaned up: the Bitwarden Secrets
Manager item `gluetun-secret`, and the `gluetun` client in the Keycloak `master` realm.

If the UK exit is ever needed again, the surgical option is a separate gluetun Deployment
with its HTTP proxy enabled (`HTTPPROXY: "on"`, port 8888) with only the affected M3U
account pointed at it through an ffmpeg stream profile (`-http_proxy http://…:8888`), rather
than putting this whole pod back behind a tunnel.

## Primary provider guide times are relabelled

The primary IPTV provider's XMLTV is generated in **Central European local time but stamped `+0000`**, so
every listing from it landed two hours late under CEST (one under CET). Dispatcharr parses
offsets correctly and has no per-source time shift, so the fix sits in front of it: the
`epg-tz-fixer` sidecar ([`epg-tz-fixer.yaml`](epg-tz-fixer.yaml)) fetches the feed,
reinterprets each `+0000` stamp as `Europe/Berlin` wall-clock time, and serves true UTC.

That provider's EPG source URL — in Dispatcharr's database, not Git — is therefore:

```
http://127.0.0.1:9290/?url=<url-encoded provider xmltv.php URL>
```

It listens on loopback only, so it has no Service and only this pod's containers (Celery
does the fetching) can reach it. If the pod is ever split up, that URL stops resolving.

To check it, compare a listing against a frame of what is airing — ESPN's weekday morning
block is unambiguous (*Get Up* 8–10 am ET, *First Take* 10–12, *The Pat McAfee Show* 12–3).
If listings ever run **early** instead, the provider has started emitting real UTC: point
the source back at the provider URL directly and drop the sidecar.

## Channel shutdown delay: 2 s, and the account allows ONE connection

**The primary provider enforces `max_connections: 1`** (see `player_api.php` → `user_info`), so only one
channel can play at a time across everything that uses Dispatcharr. The M3U account and its
default profile are set to `max_streams: 1` to match (database, not Git). While they said
"unlimited", Dispatcharr opened second connections that the provider answered with HTTP 500
on *every* channel — and enough of those got the account temporarily refused outright.

*Settings → Proxy → Channel Shutdown Delay* is **2 s** (database, not Git). nodecast-tv opens
every channel twice back to back: an `ffprobe`, then the real transcode session. With the
delay at 0 the probe's disconnect started a teardown, and the session arriving ~150 ms later
got `Refusing to initialize channel …; teardown or pending shutdown active` → HTTP 500. Any
delay fixes that (`Cancelled pending shutdown … (client reconnected)`); keep it short,
because the old channel holds the only provider connection for that long after a channel
switch. 10 s made switching slow.

A nodecast-tv transcode session can outlive its viewer and keep a channel streaming. With
one connection that blocks everything else — check `ps` in the nodecast-tv pod for a
long-running `ffmpeg` if every channel suddenly fails.

Relatedly, `Redis command failed during ownership acquisition` in the logs is not a Redis
fault: redis-py returns `None` from `SET NX` when the key already exists, which Dispatcharr
reports as a failure. It shows up in exactly this reconnect race.

## Provider server-host failover

Some providers serve one account from several interchangeable hostnames (same login, same
stream IDs). Dispatcharr keeps a single `server_url` per account, and its failover only moves
between *different streams*, so a dead host takes every stream from that account down
together.

[`iptv-host-failover.yaml`](iptv-host-failover.yaml) is a CronJob (every 5 min) that checks
each account's primary with a `player_api.php` login and, if it fails, points the account's
**default profile** at the first healthy alternate (`^https?://[^/]+` → that host). It
returns to the primary as soon as that answers again, and leaves a default profile with any
other custom pattern alone. Look for `SWITCHED` in the job logs.

**The alternate hosts are kept in Dispatcharr, not in Git.** On the account, add *disabled*
profiles named `Failover 1`, `Failover 2`, … with search `^https?://[^/]+` and replace set to
the alternate host. Disabled profiles are never used for streaming, and any account with at
least one of them is managed automatically.

It rewrites at play time rather than editing `server_url` on purpose: streams are hashed on
their URL (`m3u_hash_key: url`), so changing the host would make the next M3U refresh treat
every stream as new and silently drop the backups attached to channels. While the primary
is down the account's own M3U/EPG refresh (which uses `server_url`) will fail; existing
streams keep playing through the alternate.

## Co-located tools

Containers in different pods cannot share a network namespace, so the only way to put a
tool on the old tunnel was to put it in this pod. Three companion tools — the ones that
fetch from the public internet — therefore run here as ordinary containers of the
`dispatcharr` controller:

| Container | Container port | Service | Published port |
| --- | --- | --- | --- |
| `app` (Dispatcharr) | 9191 | `dispatcharr` | 9191 |
| `teamarr` | 9195 | `teamarr` | 9195 |
| `webpage-hls` | **3001** (+ **8081** internal) | `webpage-hls` | 3000 |
| `game-thumbs` | **3002** | `game-thumbs` | 3000 |

**The tunnel is gone but this layout stays.** Splitting them back into their own pods would
mean moving Services and PVCs between Flux Kustomizations and rewriting the M3U/EPG URLs
held in Dispatcharr's Postgres database, which are not in Git. Nothing is gained by it.

The two that stayed independent — `enhanced-channel-manager` and `epg-matcharr` — only talk
to Dispatcharr in-cluster.

### Ports had to move, Services did not

One network namespace means one port space. Several containers wanted `:3000` — including
the since-removed `vpn-ui` — and Dispatcharr itself already binds `5656`, `8001` and `9999`
internally. The two losing tools were moved with their own `PORT` env var, which both Node
apps read as `process.env.PORT`. Removing gluetun and `vpn-ui` freed `53`, `3000` and
`8000`, but the moved ports stay where they are: see below.

Their **Services still publish 3000** and simply retarget the new container port, so nothing
downstream changed: the HTTPRoutes are untouched, and the M3U/EPG URLs stored in
Dispatcharr's Postgres database — which are not in Git — keep resolving.

> **A container can bind more than the port it serves.** `webpage-hls` also runs an embedded
> WeatherStar 4000+ — the page it screenshots — on `WS4KP_PORT`, which the image bakes to
> **8080**. That collided with another container then in this pod and crashlooped it with
> `[Errno 98] Address in use` on the first deploy while everything else came up fine.
> `WS4KP_PORT: 8081` fixes it; `index.js` uses that value both to listen and to build the
> `http://localhost:<port>` URL it renders, so nothing external cares.
>
> Comparing declared Service ports is not enough. After adding a container here, check what
> the pod is really listening on:
>
> ```bash
> kubectl -n media exec deploy/dispatcharr -c app -- grep " 0A " /proc/net/tcp /proc/net/tcp6
> ```

That preservation is also why every service in `helmrelease.yaml` carries `forceRename`.
With more than one service defined, app-template names them `dispatcharr-<identifier>`,
which would have renamed the `dispatcharr` Service itself.

### What each tool directory still holds

`../tools/<tool>/` keeps its `pvc.yaml` and `httproute.yaml`, and each keeps its own Flux
Kustomization. The claims deliberately did **not** move into this directory: `nfs-slow`
reclaims `Delete`, and handing a PVC from one Flux Kustomization to another risks the old
one pruning it before the new one adopts it.

So in [`../ks.yaml`](../ks.yaml) the dependency runs `dispatcharr` → all four co-located
tools, the reverse of the remaining two. That direction is required for `teamarr`, which owns
a PVC, and it also orders the cutover: those Kustomizations prune the old per-tool
HelmReleases, and **Helm will not adopt a Service owned by another release** — it fails with
`invalid ownership metadata`. The old `teamarr`, `webpage-hls` and
`game-thumbs` releases must be uninstalled before this one upgrades.

`wait: false` means Flux does not block on those uninstalls actually finishing, so the race
is narrowed rather than eliminated. If the HelmRelease lands on `invalid ownership
metadata`, the old release simply had not finished going away:

```bash
kubectl -n media get helmrelease   # confirm the six are gone
flux -n flux-system reconcile ks dispatcharr --with-source
```

### Consequences

- **Any of these three updating restarts Dispatcharr** and drops in-flight streams. Renovate
  bumps them independently, and `webpage-hls` tracks a rolling tag by digest. This was accepted knowingly; pin those tags if it becomes disruptive.
- `strategy: Recreate` is now spelled out on the controller. It is app-template's default,
  and still required — `dispatcharr-data` and `teamarr-data` are ReadWriteOnce, so a second
  pod could never mount them alongside the first.
- Memory limits are per-container, so one tool OOMing kills only itself. Requests total
  ~2.8 Gi and ~240m CPU for the pod.
