# [Spegel](https://github.com/spegel-org/spegel)

Spegel is a stateless, cluster-local OCI registry mirror. When a node needs to pull a container image, it first checks if any other node already has it — if so, it pulls the layers peer-to-peer rather than from the upstream registry. This reduces external registry traffic and speeds up deployments when images are already present in the cluster.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Containerd socket | `/run/containerd/containerd.sock` | Spegel integrates directly with the container runtime |
| Registry config path | `/etc/cri/conf.d/hosts` | Talos path for containerd registry host configurations |
| Registry host port | `29999` | Local port Spegel listens on for peer image requests |

Spegel requires no persistent storage and adds no latency when an image is not already cached by another node — it transparently falls back to the upstream registry.

## Links

- [Documentation](https://spegel.dev/)
- [Helm Chart](https://github.com/spegel-org/spegel/tree/main/charts/spegel)
- [GitHub Repository](https://github.com/spegel-org/spegel)
