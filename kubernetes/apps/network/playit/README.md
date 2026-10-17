# [playit.gg](https://playit.gg)

`playitd` opens an outbound tunnel to playit.gg so players can reach the
Minecraft servers through a playit address instead of the home IP. Players
connect to playit's edge, the agent carries the traffic into the cluster, and
the agent connects on to Velocity on `wing-proxy` (`192.168.50.100:25565`).

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/playit-cloud/playit-agent:1.0.10` (digest-pinned) | Latest non-prerelease |
| Replicas | `1` (Recreate) | One agent per secret key |
| Run as user/group | `65534:65534` (nobody) | Read-only root; `/run/playit` and `/tmp` are emptyDirs |
| Memory limit | `128Mi` | |

There is no metrics endpoint or health port, so there are no probes or
ServiceMonitor.

## Tunnels

Tunnels live in the playit.gg dashboard, not in Git. Each one points at a
local address the agent can reach from the pod network:

| Tunnel | Protocol | Local address |
| --- | --- | --- |
| Minecraft Java | TCP | `192.168.50.100:25565` (Velocity) |
| Minecraft Bedrock | UDP | `192.168.50.100:19132` |

## Secrets

`playit-secret` (Bitwarden Secrets Manager via ExternalSecrets) holds the
agent's secret key in its `secret_key` field. Create the agent on playit.gg
(Docker setup) and copy the key it shows.

## Cutover

1. Check the tunnel address reaches the server.
2. Disable the `Minecraft (Java)` and `Minecraft (Bedrock)` UniFi port
   forwards to `192.168.50.100`. Until then the home IP still serves the
   game directly and the tunnel hides nothing.
3. If VLAN 50 is firewalled from the cluster (see the calagopus README),
   allow the cluster to reach `192.168.50.100` on 25565/tcp and 19132/udp.

Behind the tunnel every player appears to come from the agent's pod IP.
Enable PROXY protocol on the tunnel and in Velocity (`haproxy-protocol =
true`) to keep real client IPs for bans and rate limits; both ends must change
together or logins fail.

## Links

- [GitHub Repository](https://github.com/playit-cloud/playit-agent)
