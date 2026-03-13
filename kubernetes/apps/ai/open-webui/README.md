# [Open WebUI](https://github.com/open-webui/open-webui)

A self-hosted web interface for interacting with large language models. In this cluster it serves as the front-end for an Ollama instance running on external Jetson hardware, keeping GPU inference off the cluster while the UI remains cluster-managed.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Ollama backend | `http://jetson.ewatkins.dev:11434` | External Jetson host running the inference engine |
| Persistent data | `open-webui-config` PVC at `/app/backend/data` | Stores user settings, chat history, and model configs |

## Links

- [Documentation](https://docs.openwebui.com/)
- [GitHub Repository](https://github.com/open-webui/open-webui)
