# [Open WebUI](https://github.com/open-webui/open-webui)

A self-hosted web interface for interacting with large language models. In this cluster it serves as the front-end for an Ollama instance running on external Jetson hardware, keeping GPU inference off the cluster while the UI remains cluster-managed.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `ghcr.io/open-webui/open-webui:v0.8.10` | Pinned by digest |
| Helm chart | `bjw-s/app-template` v3.7.3 | |
| Ollama backend | `http://jetson.ewatkins.dev:11434` | External Jetson host running the inference engine |
| Ollama API enabled | `true` | `ENABLE_OLLAMA_API=true` |
| Service port | `8080` | |
| CPU request | `500m` | |
| Memory limit | `2Gi` | |
| Persistent data | `open-webui-config` PVC, 5Gi, `nfs-fast` | Mounted at `/app/backend/data`; stores user settings, chat history, and model configs |
| Ingress | Disabled (Helm) | Routing handled by Gateway API |
| Hostname | `chat.ewatkins.dev` | |
| Gateway | `network/internal` (HTTPS) | Internal gateway |
| External DNS target | `internal.ewatkins.dev` | |
| HSTS | `max-age=31449600; includeSubDomains` | Applied via response header modifier |
| Request timeout | `3600s` | Set via `BackendTrafficPolicy` to support long-running LLM responses |

## Flux Kustomizations

| Kustomization | Path | Interval |
| --- | --- | --- |
| `open-webui` | `kubernetes/apps/ai/open-webui/app` | 1h |

## Links

- [Documentation](https://docs.openwebui.com/)
- [GitHub Repository](https://github.com/open-webui/open-webui)
- [Helm Chart (bjw-s app-template)](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template)
