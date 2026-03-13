# [Recommendarr](https://github.com/tannermiddleton/recommendarr)

Recommendarr analyzes the existing Sonarr and Radarr libraries and uses large language models to suggest new TV shows and movies that fit the collection's taste profile.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| URL | `https://recommend.ewatkins.dev` | Publicly accessible via Cloudflare tunnel |
| Data storage | `recommendarr-data` PVC | Persists LLM settings, Sonarr/Radarr connection details, and recommendation history |

## Links

- [GitHub Repository](https://github.com/tannermiddleton/recommendarr)
