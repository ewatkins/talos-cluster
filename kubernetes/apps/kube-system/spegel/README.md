# [Spegel](https://github.com/spegel-org/spegel)

Spegel is a stateless, cluster-local OCI registry mirror. When a node needs to pull a container image, it checks whether any peer node already has it cached in containerd. If a peer has the layers, they are transferred directly over the cluster network rather than fetched from the upstream registry. When no peer has the image, Spegel transparently falls back to the upstream registry with no added latency.

## Chart

| Field | Value |
| --- | --- |
| Chart | `spegel/spegel` |
| Version | `0.6.0` |
| Source | HelmRepository `spegel` in `flux-system` |

## Configuration

| Setting | Value |
| --- | --- |
| Containerd socket | `/run/containerd/containerd.sock` |
| Registry config path | `/etc/cri/conf.d/hosts` |
| Registry host port | `29999` |
| ServiceMonitor | enabled |

- **Containerd socket**: Spegel integrates directly with the containerd CRI to inspect and serve locally cached image layers.
- **Registry config path**: Talos stores containerd registry host configurations at `/etc/cri/conf.d/hosts`. Spegel writes mirror entries here so containerd redirects pulls through the local Spegel listener.
- **Registry host port `29999`**: Each node listens on this port to serve image layers to peers.

Spegel requires no persistent storage or external coordination — peer discovery uses the Kubernetes API.

## Links

- [Documentation](https://spegel.dev/)
- [Helm Chart](https://github.com/spegel-org/spegel/tree/main/charts/spegel)
- [GitHub Repository](https://github.com/spegel-org/spegel)
