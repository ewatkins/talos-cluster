# tailscale

In-cluster Tailscale, deployed via the official **tailscale-operator** Helm
chart. Replaces the standalone Tailscale VM: a cluster-native subnet router +
exit node ([`connector/connector.yaml`](connector/connector.yaml)) advertises
the home subnets onto the tailnet.

## Layout

- `app/` — the operator (`HelmRelease`) and its OAuth `ExternalSecret`, in the
  `network` namespace. That namespace is marked **privileged** via the
  `privileged-namespace` component (in `network/kustomization.yaml`): the
  subnet-router / exit-node proxy pods the operator spawns need `NET_ADMIN` +
  `/dev/net/tun`, which Talos's default `baseline` PodSecurity blocks.
- `connector/` — the cluster-scoped `Connector` (applied after the operator's
  CRDs exist, via `dependsOn`).

## Advertised routes

Defined in [`connector/connector.yaml`](connector/connector.yaml):

| Route               | Purpose                          |
| ------------------- | -------------------------------- |
| `192.168.1.0/24`    | primary LAN / UniFi gateway      |
| `192.168.30.0/24`   | home network                     |
| `192.168.40.0/24`   | cluster / services network       |
| `192.168.50.0/24`   | home network                     |
| `192.168.60.0/24`   | storage / NAS network            |
| `192.168.70.0/24`   | home network                     |
| `192.168.80.0/24`   | home network                     |
| `192.168.255.0/24`  | management network               |

Exit-node duty is enabled (`exitNode: true`).

## Manual prerequisites (one-time)

1. **OAuth client** — in the Tailscale admin console
   (Settings → OAuth clients), create a client with the **Devices → Core**
   *write* scope, and tag it (e.g. `tag:k8s-operator`). Store it in Bitwarden
   Secrets Manager as an item named **`tailscale-secret`** with fields:
   - `client_id`
   - `client_secret`

   The `tailscale-secret` `ExternalSecret` syncs this into the cluster as the
   `operator-oauth` Secret that the operator mounts.
2. **Approve routes / exit node** — after the `Connector` registers, approve
   the advertised subnet routes and exit node under the device's settings in the
   admin console. To skip manual approval, add `autoApprovers` for the operator
   tag in your tailnet ACL policy.
3. Once verified, **decommission the standalone Tailscale VM**.
