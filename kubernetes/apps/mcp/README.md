# MCP

Model Context Protocol servers that expose cluster-adjacent systems as tools for LLM agents. Each server speaks streamable HTTP so agents (Claude Code, Open WebUI, n8n) can attach over the network rather than spawning a local stdio process.

Flux alerts for this namespace are routed to Alertmanager at `alertmanager-operated.observability.svc.cluster.local:9093`.

## Apps

| App | Description |
| --- | --- |
| [proxmox-mcp](proxmox-mcp/README.md) | Proxmox VE tools at `proxmox-mcp.ewatkins.dev` |
| [unifi-network-mcp](unifi-network-mcp/README.md) | UniFi Network controller tools at `unifi-mcp.ewatkins.dev` |
