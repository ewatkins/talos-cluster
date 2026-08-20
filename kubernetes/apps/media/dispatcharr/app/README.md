# Dispatcharr

IPTV channel manager. Runs in modular mode: Postgres (Crunchy pg17) and Redis (Dragonfly
db5) are external, Celery runs as its own container, and all of it egresses through a
Privado VPN tunnel pinned to the UK so UK-geolocked streams are reachable.

The pod also hosts **six of the companion tools** — the ones that fetch from the public
internet — so they share the same tunnel. See [Co-located tools](#co-located-tools).

| | |
| --- | --- |
| URL | `https://dispatcharr.ewatkins.dev` |
| VPN UI | `https://gluetun.ewatkins.dev` |
| Companion tools | [`../tools/README.md`](../tools/README.md) |

## VPN sidecar

[gluetun](https://github.com/qdm12/gluetun) runs as a **native sidecar** — an init container
with `restartPolicy: Always`, so it starts first, its startup probe gates the app containers,
and it shuts down last. Every container in the pod shares its network namespace, so
Dispatcharr, Celery, the VPN UI and the six co-located tools all leave through the tunnel,
and gluetun's kill switch drops their traffic whenever it is down.

Privado is OpenVPN-only in gluetun — WireGuard support for this provider is unmerged
([#2645](https://github.com/qdm12/gluetun/issues/2645),
[#3159](https://github.com/qdm12/gluetun/issues/3159)).

### Why the exit is pinned by hostname, not by country

`SERVER_COUNTRIES: United Kingdom` **does not work** on gluetun v3.41.1. That release builds
its baked-in Privado server list by geolocating each endpoint's IP via ipinfo, and Privado's
UK endpoints sit in Leaseweb/Eweka netblocks, so gluetun files all of them under
*Netherlands / Amsterdam*. The only countries it will accept for Privado are Estonia,
Netherlands and United States — a country filter would be rejected at startup, and an
unfiltered setup would land in the UK roughly 5% of the time.

Gluetun is the outlier — but only for London. Checking every exit address against several
databases splits Privado's UK estate in two:

| Exit block | Endpoints | ipwho.is | ip-api.com | ip2location / cloudflare / ifconfig.co |
| --- | --- | --- | --- | --- |
| `81.171.74.0/24` | `lhr-060…065` | GB / London | GB / London | **UK** |
| `91.148.228.0/24` | `man-009,010` | GB / Manchester | GB / Manchester | **Netherlands** |

So [`configmap.yaml`](configmap.yaml) pins `SERVER_HOSTNAMES` to the **six London endpoints
only**. Manchester is excluded on purpose: two databases call it GB and three call it NL, and
a streaming service using one of the latter would geoblock exactly the same way it would
without a VPN. London reads GB everywhere. Gluetun picks one of the six at random per
connect.

**ipinfo is the reason gluetun mislabels these servers**, and it is also gluetun's default
public-IP API — which is why the UI reported *Netherlands / Lelystad* for a UK exit.
`PUBLICIP_API: ifconfigco,ip2location,cloudflare` drops it, and with the pool restricted to
London the UI now agrees with everything else: *United Kingdom, England, Covent Garden*.

### The exit IP in the UI can lag the real one

Gluetun looks up its public IP **only when the tunnel connects**, and the UI just renders
that cached value. If the lookup fails the old value stays on screen — or it blanks to `""`
— while traffic is already leaving through the new exit. Reconnecting several times in a row
is enough to trip it, since every provider in the list rate-limits:

```
ERROR [vpn] getting public IP address information: fetching information: all fetchers failed
```

Measured during one such window: the control server reported `{"public_ip":""}` while the
`app` container's own request came back `81.171.74.32`. **Believe the container, not the
UI**, and check it directly:

```bash
kubectl -n media exec deploy/dispatcharr -c app -- \
  python3 -c "import urllib.request;print(urllib.request.urlopen('http://ip-api.com/json/').read().decode())"
```

Each pinned endpoint does have its own distinct exit address — `lhr-060` → `81.171.74.32`,
`lhr-061` → `.41`, `lhr-065` → `.67` — so stop/start really does move you. With six servers
in the pool, roughly one cycle in six lands you back on the one you just left.

> **On upgrades:** `SERVER_HOSTNAMES` is validated against the list baked into the image, so
> if a Renovate bump of gluetun drops or renames one of these hostnames, the sidecar will
> refuse to start and Dispatcharr stays down with it. Newer gluetun builds read Privado's
> [official server export](https://privadovpn.com/apps/servers_export.json), where the
> country really is `United Kingdom`; once that lands in a tagged release, switch this back
> to `SERVER_COUNTRIES: United Kingdom` and the fragility goes away.

### What stays off the tunnel

`FIREWALL_OUTBOUND_SUBNETS` keeps three CIDRs on `eth0`:

| Subnet | Why |
| --- | --- |
| `192.168.40.0/24` | LAN: the NAS, the nodes, and kubelet probe replies |
| `10.69.0.0/16` | Pod CIDR: the Envoy gateway, the Dispatcharr tools |
| `10.96.0.0/16` | Service CIDR: CoreDNS, pgBouncer, Dragonfly |

> **Give DNS ~2 minutes after a pod roll before diagnosing anything.** Gluetun's forwarder
> logs `[dns] ready` while its DoT upstream is still warming up, so public names fail with
> `Temporary failure in name resolution` for a window after startup — cluster names keep
> resolving the whole time, which makes it look like a split-DNS bug. Worse, gluetun's own
> healthcheck used to resolve `github.com`/`cloudflare.com` through that same forwarder, so if
> the window is long enough it fails, restarts the VPN, and loops. One clean `rollout restart`
> cleared it. `HEALTH_TARGET_ADDRESSES: 1.1.1.1:443,8.8.8.8:443` now takes DNS out of that
> path so a stalled forwarder can no longer escalate into a restart storm — but the forwarder
> itself can still wedge, and a roll is still the way out. Confirm with
> `kubectl -n media exec deploy/dispatcharr -c gluetun -- nslookup
> github.com 127.0.0.1` before concluding the tunnel or the firewall is at fault.

Anything **not** listed routes into `tun0` and is blackholed at the Privado exit — that is
the kill switch working as intended, but it also means a forgotten LAN segment looks like a
dead host: `ping 10.0.100.221` succeeds from any other pod and fails from this one.

**That asymmetry is not a bug, and it is not an ingress path.** The client VLAN
(`10.0.0.0/16`) was added here once while chasing an XC client that could not log in, then
removed again, because this list only governs connections the pod *initiates*. Clients
connect **inbound** through the gateway, which runs `externalTrafficPolicy: Cluster` and
SNATs every request to a pod IP — Dispatcharr only ever sees `10.69.x.x` — and reply
routing for an inbound connection does not consult this list at all. Widening it cannot fix
a client-side auth or connectivity failure; it only enlarges what bypasses the tunnel.

> **The VPN UI leaks the Privado credentials, so it is behind Keycloak.** Gluetun's
> `/v1/vpn/settings` returns `openvpn.user` and `openvpn.password` in clear text, and
> gluetun-webui re-serves that verbatim on its own `/api/health`. Left open, anything on the
> LAN could read them, so [`securitypolicy.yaml`](securitypolicy.yaml) puts the route behind
> OIDC — same pattern as [garage-webui](../../../storage/garage/webui/securitypolicy.yaml).
> Keycloak client `gluetun` in the `master` realm, redirect URI
> `https://gluetun.ewatkins.dev/oauth2/callback`, secret in the Bitwarden item
> `gluetun-secret` under `CLIENT_SECRET`.

`FIREWALL_INPUT_PORTS` is `9191,3000,3001,3002,9195` — Dispatcharr, the VPN
UI and the three co-located tools. Gluetun's control server on `:8000` is deliberately left
out, so it is reachable only from inside the pod; that is why it runs with
`{"auth":"none"}`. If you ever expose `:8000`, switch it to
`{"auth":"apikey","apikey":"..."}` (generate with `docker run --rm qmcgaw/gluetun genkey`)
and give the UI a matching `GLUETUN_API_KEY` — it sends the key as `X-API-Key`, which is
what gluetun expects.

### Changing the exit without a commit

Gluetun cannot switch servers over its API
([qdm12/gluetun#2473](https://github.com/qdm12/gluetun/issues/2473) is still open), so there
are two levers, neither of which needs a Git change:

**Roll onto a different UK exit** — the *stop* then *start* buttons at
`gluetun.ewatkins.dev`. Gluetun re-runs server selection on each connect and lands on
another of the eight pinned endpoints. The UI also shows live status, exit IP, city, org
and protocol.

**Move somewhere else entirely** — edit the ConfigMap:

```bash
kubectl -n media edit configmap dispatcharr-vpn-server
# swap SERVER_HOSTNAMES, or use SERVER_COUNTRIES: United States
```

`configmap.yaml` carries `kustomize.toolkit.fluxcd.io/ssa: IfNotPresent`, so Flux creates it
once and never overwrites it — the edit sticks, and Reloader rolls the pod onto the new
exit. The flip side is that fixing a bad value in Git is not enough: delete the live
ConfigMap and let Flux recreate it. Two settings gluetun rejects for Privado, both of which
fail the sidecar at startup: `OPENVPN_PROTOCOL: tcp`, and any `OPENVPN_ENDPOINT_PORT` at
all. Note that this restarts Dispatcharr and drops any in-flight streams; the UI's
stop/start does not. Confirm what the world sees with:

```bash
kubectl -n media exec deploy/dispatcharr -c vpn-ui -- wget -qO- https://ipwho.is
```

To make a change permanent, copy it back into `configmap.yaml` and delete the live
ConfigMap so Flux recreates it.

### Credentials

`gluetun-secret` comes from the Bitwarden Secrets Manager item of the same name, as JSON
with `OPENVPN_USER` and `OPENVPN_PASSWORD`. These are the **OpenVPN service credentials**
from the Privado dashboard (Manual Configuration), not the website login.

### Trade-offs

- **Everything in this pod now originates in the UK**, including M3U and EPG fetches, all
  client stream proxying, and the six co-located tools. Any US-geolocked source may start
  failing; if that happens, either swap the exit per the section above, or go surgical:
  move gluetun into its own Deployment with its HTTP proxy enabled (`HTTPPROXY: "on"`,
  port 8888) and point only the UK M3U account at it through an ffmpeg stream profile
  (`-http_proxy http://…:8888`).
- Playback throughput is capped by the VPN, and Privado's free tier is bandwidth-limited —
  now shared with every co-located tool.
- The tunnel is a single point of failure for the whole pod: if gluetun cannot connect,
  neither Dispatcharr nor any co-located tool starts (by design — that is the startup probe
  gating them).
- The pod requires `NET_ADMIN`. Gluetun creates `/dev/net/tun` itself using the default
  `MKNOD` capability, so no privileged mode or device mount is needed.
- No `UPDATER_PERIOD`: the runtime updater in v3.41.1 re-derives the server list through IP
  geolocation, which is exactly what mislabels the UK endpoints. The baked-in list is
  deterministic and the image is digest-pinned, so leave it off.

## Co-located tools

Containers in different pods cannot share a network namespace, so the only way to put a
tool on this tunnel is to put it in this pod. Six of the eleven companion tools — every one
that fetches from the public internet — therefore run here as ordinary containers of the
`dispatcharr` controller:

| Container | Container port | Service | Published port |
| --- | --- | --- | --- |
| `app` (Dispatcharr) | 9191 | `dispatcharr` | 9191 |
| `vpn-ui` | 3000 | `dispatcharr` | 3000 |
| `teamarr` | 9195 | `teamarr` | 9195 |
| `webpage-hls` | **3001** (+ **8081** internal) | `webpage-hls` | 3000 |
| `game-thumbs` | **3002** | `game-thumbs` | 3000 |

The two that stayed independent — `enhanced-channel-manager` and `epg-matcharr` — only talk
to Dispatcharr in-cluster, so a tunnel would add latency and gain nothing.

### Ports had to move, Services did not

One network namespace means one port space. Four containers wanted `:3000`, and Dispatcharr
itself already binds `5656`, `8001` and `9999` internally while gluetun holds `53` (its DNS
resolver) and `8000` (its control server). The two losing tools were moved with their own
`PORT` env var, which both Node apps read as `process.env.PORT`.

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
