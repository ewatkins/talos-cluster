# Dispatcharr

IPTV channel manager. Runs in modular mode: Postgres (Crunchy pg17) and Redis (Dragonfly
db5) are external, Celery runs as its own container, and all of it egresses through a
Privado VPN tunnel pinned to the UK so UK-geolocked streams are reachable.

| | |
| --- | --- |
| URL | `https://dispatcharr.ewatkins.dev` |
| VPN UI | `https://gluetun.ewatkins.dev` |
| Companion tools | [`../tools/README.md`](../tools/README.md) |

## VPN sidecar

[gluetun](https://github.com/qdm12/gluetun) runs as a **native sidecar** — an init container
with `restartPolicy: Always`, so it starts first, its startup probe gates the app containers,
and it shuts down last. Every container in the pod shares its network namespace, so
Dispatcharr, Celery and the VPN UI all leave through the tunnel, and gluetun's kill switch
drops their traffic whenever it is down.

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
| `10.40.0.0/16` | LAN: the NAS, the nodes, and kubelet probe replies |
| `10.69.0.0/16` | Pod CIDR: the Envoy gateway, the Dispatcharr tools |
| `10.96.0.0/16` | Service CIDR: CoreDNS, pgBouncer, Dragonfly |

> **The VPN UI leaks the Privado credentials, so it is behind Keycloak.** Gluetun's
> `/v1/vpn/settings` returns `openvpn.user` and `openvpn.password` in clear text, and
> gluetun-webui re-serves that verbatim on its own `/api/health`. Left open, anything on the
> LAN could read them, so [`securitypolicy.yaml`](securitypolicy.yaml) puts the route behind
> OIDC — same pattern as [garage-webui](../../../storage/garage/webui/securitypolicy.yaml).
> Keycloak client `gluetun` in the `master` realm, redirect URI
> `https://gluetun.ewatkins.dev/oauth2/callback`, secret in the Bitwarden item
> `gluetun-secret` under `CLIENT_SECRET`.

`FIREWALL_INPUT_PORTS` is `9191,3000` — Dispatcharr and the VPN UI. Gluetun's control
server on `:8000` is deliberately left out, so it is reachable only from inside the pod;
that is why it runs with `{"auth":"none"}`. If you ever expose `:8000`, switch it to
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

- **Everything Dispatcharr does now originates in the UK**, including M3U and EPG fetches
  and all client stream proxying. Any US-geolocked source may start failing; if that
  happens, either swap the exit per the section above, or go surgical: move gluetun into
  its own Deployment with its HTTP proxy enabled (`HTTPPROXY: "on"`, port 8888) and point
  only the UK M3U account at it through an ffmpeg stream profile
  (`-http_proxy http://…:8888`).
- Playback throughput is capped by the VPN, and Privado's free tier is bandwidth-limited.
- The tunnel is a single point of failure for the whole pod: if gluetun cannot connect,
  Dispatcharr's containers never start (by design — that is the startup probe gating them).
- The pod requires `NET_ADMIN`. Gluetun creates `/dev/net/tun` itself using the default
  `MKNOD` capability, so no privileged mode or device mount is needed.
- No `UPDATER_PERIOD`: the runtime updater in v3.41.1 re-derives the server list through IP
  geolocation, which is exactly what mislabels the UK endpoints. The baked-in list is
  deterministic and the image is digest-pinned, so leave it off.
