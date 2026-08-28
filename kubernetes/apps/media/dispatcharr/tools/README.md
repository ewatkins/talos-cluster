# Dispatcharr Tools

Five companion services around [Dispatcharr](../app/), the IPTV channel manager. Each is
its own Flux `Kustomization` in [`../ks.yaml`](../ks.yaml).

> **Three of them do not run in their own pod.** `teamarr`, `webpage-hls` and `game-thumbs`
> run as containers inside the **Dispatcharr pod**. They were put there to share its gluetun
> VPN tunnel; that tunnel has since been removed, but they stay co-located because their
> Services and the M3U/EPG URLs stored in Dispatcharr's database are built around it.
> Their images, env, probes and resources live in
> [`../app/helmrelease.yaml`](../app/helmrelease.yaml); the directories here keep only their
> PVC and HTTPRoute. Full rationale in [`../app/README.md`](../app/README.md#co-located-tools).
>
> Every Service name and published port was preserved, so nothing below changes address.
> The other two keep their own Deployments and declare `dependsOn: dispatcharr`; `teamarr`,
> the one co-located tool that owns a PVC, has that dependency reversed, since the Dispatcharr
> pod mounts its claim.

> **On the URLs below:** which M3U accounts and EPG sources Dispatcharr actually has
> registered lives in Dispatcharr's own Postgres database, not in Git. The URLs given here are
> the integration points each tool exposes — verify the live wiring in the Dispatcharr UI
> under *M3U Accounts* and *EPG Sources*.

They fall into three roles (★ = runs inside the Dispatcharr pod):

| Role | Tools |
|---|---|
| **Feed content in** — Dispatcharr pulls M3U/XMLTV from them | `teamarr`★, `webpage-hls`★ |
| **Curate what's there** — they call the Dispatcharr API | `enhanced-channel-manager`, `epg-matcharr` |
| **Artwork** | `game-thumbs`★ |

```mermaid
flowchart LR
    subgraph SRC["Content sources"]
        TEAM["teamarr<br/>sports XMLTV"]
        HLS["webpage-hls<br/>HLS stream"]
    end

    DISP{{"Dispatcharr :9191"}}

    subgraph CUR["Curation via Dispatcharr API"]
        ECM["enhanced-channel-manager"]
        MATCH["epg-matcharr"]
    end

    subgraph ART["Artwork"]
        THUMB["game-thumbs"]
    end

    JELLY(["Jellyfin<br/>:8096"])

    TEAM & HLS -->|pulled by| DISP
    DISP <-->|read + write| ECM & MATCH
    THUMB -.->|thumbnail URLs| TEAM
    DISP -->|channels + logos| JELLY
```

## Feeding content into Dispatcharr

### `teamarr` — dynamic sports EPG

Self-described as a "Sports EPG generation service". Builds guide data for sports channels
from league/team metadata (**168 mappings across 7 providers and 17 sports**, plus 216 ESPN
soccer leagues cached at startup).

It goes further than a plain source — its API includes `/api/v1/channels/dispatcharr/{id}`,
`/api/v1/channels/managed`, and `/api/v1/channels/reconciliation/*`, so it both generates
EPG *and* manages the Dispatcharr channels it generates for.

Its Dispatcharr connection is configured **in the teamarr UI**, not via env — there is no
`DISPATCHARR_URL` in the HelmRelease. State lives in `teamarr.db` on the `teamarr-data` PVC.

### `webpage-hls` — webpage → HLS transcoder

Runs [`ws4kp-to-hls`](https://github.com/sethwv/ws4kp-to-hls): renders a web page in headless
Chromium and re-encodes the result as an HLS stream, so a website becomes a watchable
channel. Built for [WeatherStar 4000+](https://github.com/netbymatt/ws4kp).

- `/weather?city=…` — the packaged weather channel
- `/stream?url=…` — any arbitrary page (400 without `url`)
- `/health` — liveness (`/` returns 404 **by design**)

The container listens on **:3001** (`PORT`) — originally to stay clear of the `vpn-ui`
container, which is gone; the port stays put because its Service still publishes `:3000`. It also runs a **second** server — the embedded WeatherStar it
screenshots — on `WS4KP_PORT`, moved to **:8081** because the image defaults it to `:8080`,
which collided with another container when this pod was busier. Purely pod-internal; the app builds its own
`http://localhost:8081` URL from the same variable.

It also validates a background music library at startup (66 audio files → a 1,320-track
shared playlist). Dispatcharr ingests the resulting HLS URL as a custom stream. The 2 Gi
limit and the writable `/tmp`, `/streaming-app/cache`, `/home/node/.cache` mounts exist
because of the headless browser.

## Curating what's already in Dispatcharr

### `enhanced-channel-manager` (ECM) — bulk channel operations

The heaviest tool here. Channel pipelines (a rules engine with an evaluator, executor and
rule analyzer), name normalization and abbreviation tags, bandwidth tracking, an M3U change
monitor, backup/restore, and alerting over SMTP/Discord/Telegram.

Ships a **second container**, `enhanced-channel-manager-mcp`, exposing ECM's operations as
MCP tools for LLM agents. It's a sidecar in the same pod, so they talk over localhost
(`MCP_HOST: http://localhost:6101`, `ECM_URL: http://localhost:6100`) rather than the
Service.

All state — `settings.json` (including the Dispatcharr connection), `auth_settings.json`,
`journal.db`, `uploads/`, `tls/` — lives in `CONFIG_DIR=/config` on the
`enhanced-channel-manager-config` PVC. Without that PVC every restart wiped the config and
`m3u_change_monitor` failed on each poll with `URL is missing an 'http://' or 'https://'
protocol`.

### `epg-matcharr` — channel ↔ EPG matching

Matches Dispatcharr channels against available EPG entries, so guide data lands on the right
channel. Reads `DISPATCHARR_URL` from env; the API token is set **through its UI on first
run**. `DISPATCHARR_TOKEN` is deliberately left unset rather than pinned empty, because env
vars take priority over UI settings there.

## Artwork

### `game-thumbs` — per-event thumbnail generation

Generates thumbnail artwork for sports events, consumed by URL. Pairs naturally with
`teamarr`: teamarr produces the sports guide entries, game-thumbs supplies matching images.
Rate-limited to 90 requests/minute, with an in-pod `emptyDir` at `/app/.cache`.

Its HTTP surface is unusual — most paths return **444**, but `/health` returns a normal
JSON 200, so the `tcpSocket` probe is more conservative than necessary; a `/health` httpGet
would work. The container listens on **:3002** (`PORT`) — originally to stay clear of the `vpn-ui`
container, which is gone; the port stays put because its Service still publishes `:3000`.

## Daily pipeline order

The cron schedules are staggered so each stage runs after its inputs are ready:

| Time | What runs |
|---|---|
| 03:00 | Jellyfin refreshes its XMLTV guide |

`teamarr` runs its own hourly cron.

## Conventions across these tools

**Where config actually lives.** Only `epg-matcharr` gets its Dispatcharr URL from env. `teamarr` and `enhanced-channel-manager`
store the whole connection — credentials included — in their own database, set through their
UI. Nothing in Git will reproduce that; it's why ECM needs a PVC.

**Cluster-internal addressing.** Tools should reach Dispatcharr at
`http://dispatcharr.media.svc.cluster.local:9191`, never the external hostname — the gateway
applies rate limits that will throttle a busy tool. The co-located tools can use
`http://localhost:9191` instead.

**NFS ownership.** The `nfs-slow` storage class presents as `99:100` and can't be chowned
from a container, so every tool with a PVC on it runs with `runAsUser: 99`, `runAsGroup: 100`,
`fsGroup: 100` and `fsGroupChangePolicy: OnRootMismatch` — matching Dispatcharr itself. ECM is
the exception: it runs as root, since its image expects to write files owned by its own
`appuser`. For `teamarr` this is now set **per container** rather
than pod-wide, because they share a pod with Dispatcharr's image, which starts as root and
drops to `PUID`/`PGID` itself.

**Port uniqueness.** Only inside the Dispatcharr pod, where one network namespace is shared:
`webpage-hls` and `game-thumbs` were moved off `:3000` to `:3001` and `:3002`. Their Services still publish `:3000` and retarget, so no consumer — including the
URLs stored in Dispatcharr's database — sees a change. Also unavailable in that pod: `53`,
`5656`, `8000`, `8001`, `9191`, `9999`, and `8081` (webpage-hls's embedded WeatherStar).

A container may bind ports it does not advertise — that is what collided `webpage-hls` with
another container on the first deploy. Comparing Service ports is not enough; check the pod's real
listeners with `grep " 0A " /proc/net/tcp` before adding a container.

> A stale NFS handle on one of these volumes surfaces as `unable to open database file` or
> `Stale file handle` while the PVC still reports `Bound`. A pod restart remounts it; the data
> is intact.

**No Gatus checks.** These tools are deliberately unmonitored — Dispatcharr itself keeps its
check. `game-thumbs` (444 on `/`) and `webpage-hls` (404 on `/`) would each have needed a
custom path or status anyway.

**Image pinning.** Everything is pinned by tag *and* digest for Renovate. `webpage-hls`
publishes no version tags, so it tracks a rolling tag by digest. For the three
co-located tools, that means a Renovate bump **restarts
Dispatcharr** and drops in-flight streams — accepted deliberately, but it is the reason to
pin those rolling tags if the churn ever gets annoying.
