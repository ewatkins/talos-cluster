# [Open WebUI](https://github.com/open-webui/open-webui)

Open WebUI is a user-friendly, self-hosted web interface for interacting with large language models. It supports Ollama and OpenAI-compatible APIs.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `open-webui` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

## Notes

- Image: `ghcr.io/open-webui/open-webui` v0.8.10
- Deployed via `bjw-s/app-template` chart
- Configured to connect to an external Ollama instance at `http://jetson.ewatkins.dev:11434`
- Persistent config stored in `open-webui-config` PVC mounted at `/app/backend/data`

## Links

- [Documentation](https://docs.openwebui.com/)
- [GitHub Repository](https://github.com/open-webui/open-webui)
