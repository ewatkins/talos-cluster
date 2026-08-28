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
