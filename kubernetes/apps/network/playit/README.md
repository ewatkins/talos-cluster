# Minecraft relay (Oracle Cloud)

Players join `mc.ewatkins.dev` on the default ports (Java 25565, Bedrock
19132). That name points at a small Oracle Cloud VM, `minecraft-relay`, which
forwards both editions home through port forwards that accept only the VM.
Players never see the home IP.

The directory and Flux Kustomization are still named `playit`, after the
playit.gg tunnel this replaced (removed 2026-10-19). Renaming the
Kustomization would prune and recreate the DNS record, so it was left alone.

```
player ─▶ mc.ewatkins.dev (A 170.9.242.78, DNS-only)
       ─▶ minecraft-relay: HAProxy tcp/25565 (PROXY v2), socat udp/19132
       ─▶ home WAN IP ─▶ ISP modem (192.168.0.1) ─▶ UniFi (WAN 192.168.0.2)
       ─▶ wing-proxy 192.168.50.100: Velocity (Java), Geyser (Bedrock)
```

## Relay VM

| | |
| --- | --- |
| Instance | `minecraft-relay`, us-chicago-1 AD-1, `VM.Standard.A1.Flex` 1 OCPU / 6 GB (ARM), Ubuntu 24.04 Minimal |
| Public IP | `170.9.242.78`, a reserved public IP also named `minecraft-relay`, so it outlives the VM |
| Network | `relay-vcn` / `relay-subnet`, OpenTofu in `terraform/oracle-relay` (security list: TCP 25565 and UDP 19132 from anywhere, SSH from home only, ICMP fragmentation-needed) |
| Java | `haproxy.service`: TCP 25565 to the home WAN IP, `send-proxy-v2` |
| Bedrock | `bedrock-relay.service`: `socat` UDP 19132 to the home WAN IP |
| SSH | `ewatkins@170.9.242.78` (key-only, passwordless sudo), from the home IP or the extra sources in `ssh_extra_cidrs` (`oci-api-secret`); from elsewhere jump through a wing, e.g. `-J ewatkins@192.168.50.100` |

us-chicago-1 offers no `VM.Standard.E2.1.Micro`, hence A1.Flex, inside the
Always Free 4 OCPU / 24 GB allowance. Oracle's network-level DDoS protection
covers the VM's address; there is nothing at the application layer.

## Home side

| Hop | Rule |
| --- | --- |
| ISP modem | TCP 25565 and UDP 19132 → UniFi WAN `192.168.0.2` |
| UniFi | `Minecraft (Java) from Oracle relay` TCP 25565 and `Minecraft (Bedrock) from Oracle relay` UDP 19132 → `192.168.50.100`, source `170.9.242.78` only |
| Velocity | `haproxy-protocol = true` in `velocity.toml` on wing-proxy (panel-managed file, not in Git) |

Velocity drops any Java connection that doesn't start with a PROXY header,
so everything that reaches it on 25565 must send one. The relay sends v2. The
in-cluster Gatus `velocity` check sends a v1 line
(`default/calagopus/app/gatus.yaml`). Bedrock has no PROXY header: Geyser's
Bedrock listener supports one (`bedrock.use-haproxy-protocol`), but that is
PROXY over UDP, which HAProxy can't send. Bedrock players show as the relay.

If the home WAN IP changes, update `ssh_source_cidr` in `oci-api-secret`
(Bitwarden) and the two relay services on the VM.

## DNS

`app/dnsendpoint.yaml` publishes `mc.ewatkins.dev` as a DNS-only A record for
the reserved IP, through `cloudflare-dns`. UniFi has a matching local record
for LAN clients, so LAN players take the same path and get the same PROXY
handling.

## Monitoring

The Gatus checks `relay-java` and `relay-bedrock`
(`default/calagopus/app/gatus.yaml`) ping `mc.ewatkins.dev` from the cluster,
covering DNS, the VM, both port forwards, and Velocity/Geyser.

## Rebuilding the VM

`app/relay-launcher.yaml` is a CronJob (suspended) that launches the VM
every 10 minutes until Oracle has capacity, trying each AD in turn. It finds
its VM by display name (`NAME=minecraft-relay`), so renaming the VM in the
console makes it launch another. The cloud-init it passes sets up HAProxy and
socat; `launch.sh` fills the home WAN IP in from the secret. To rebuild:

1. Terminate `minecraft-relay` (keep the reserved IP).
2. Unsuspend the CronJob. The first run launches the VM with an ephemeral IP
   and sends a Pushover notification once it is RUNNING.
3. On the VM's primary private IP, set the public IP to none, then attach
   the `minecraft-relay` reserved IP. DNS and the UniFi source rule need no
   change.
4. Suspend the CronJob again.

## Secrets

`oci-api-secret` (Bitwarden Secrets Manager via ExternalSecrets) holds the
Oracle API key and the `minecraft-relay` compartment the VM, its network and
the reserved IP live in (`user`, `tenancy`, `compartment`, `fingerprint`,
`region`, `private_key_b64`) and `ssh_source_cidr`, the home WAN IP as a /32.
`bedrock-relay-launcher-secret` combines it with the shared `pushover` item;
the OpenTofu runner reads it as `oracle-relay-secret`.
