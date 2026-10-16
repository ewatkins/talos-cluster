# [Chaptarr](https://github.com/Chaptarr/chaptarr)

Chaptarr manages the audiobook and eBook collection. It is a fork of Readarr with
richer metadata handling for narrators, editions and series, and it keeps the same
Servarr workflow: monitor indexers (via Prowlarr) for new releases, hand grabs to a
download client, then sort and rename completed downloads into the library.

## Configuration

| Setting | Value | Notes |
| --- | --- | --- |
| Image | `docker.io/chaptarr/chaptarr:0.9.965` | No `home-operations` build exists; upstream's own Docker Hub image |
| URL | `https://chaptarr.ewatkins.dev` | Internal gateway only (`internal.ewatkins.dev` DNS target) |
| Port | `80` | HTTP; overrides the image's 8789 default via `CHAPTARR__SERVER__PORT` |
| Instance name | `Chaptarr` | |
| Theme | `dark` | |
| Auth method | `External` | Authentication handled upstream; disabled for local addresses |
| Update branch | `develop` | |
| Timezone | `America/Chicago` | |
| Databases | PG17 `chaptarr-main` / `-log` / `-cache` | Via pgbouncer (`pool_mode: session`); creds from `chaptarr-db-secret` |
| Config PVC | `chaptarr-config`, 10Gi (`nfs-slow`) | Mounted at `/config`; holds `config.xml`, logs, MediaCover and `staging.db` |
| Media library | NFS `storage.ewatkins.dev:/mnt/user/arrdata` | Mounted at `/mnt/arrdata`; shared with all *arr apps |
| Run as user/group | `99:100` | |
| Memory limit | `2Gi` | Higher than the other *arr apps — audio tagging via `m4b-tool` is memory-hungry |

## Root folders

The container's documented `/audiobooks`, `/ebooks` and `/downloads` mounts are not
used. As with Sonarr and Radarr, the whole `arrdata` share is mounted once at
`/mnt/arrdata` and paths are set inside the app, so hardlinks work across the
library and download directories:

| Purpose | Path |
| --- | --- |
| Audiobook root folder | `/mnt/arrdata/media/audiobooks` |
| eBook root folder | `/mnt/arrdata/media/ebooks` |
| Download client category | `/mnt/arrdata/torrent/books` |

Root folders, like the rest of the app settings below, live in Chaptarr's
database rather than the manifests.

## App settings

Copied from the live Sonarr and Radarr configuration and adapted for books.
Applied through the API, so they are not in Git.

| Area | Setting | Source |
| --- | --- | --- |
| Media management | Hardlinks on, propers/repacks `doNotPrefer` | Sonarr + Radarr agree |
| Media management | Import extra files on (`jpg,png,cue,m3u,opf`) | Radarr; keeps covers and `.opf` metadata |
| Media management | Skip free-space check on import: off | Radarr (Sonarr has it on) |
| Media management | 100 MB minimum free, `chmod 755`, recycle bin 7 days | Sonarr + Radarr agree |
| Naming | Rename audiobooks and eBooks: on | Sonarr + Radarr |
| Naming | Replace illegal characters: off | Sonarr + Radarr agree |
| Naming | Colon replacement: Smart | Sonarr (Radarr uses space-dash-space) |
| Download client | SABnzbd `sab.ewatkins.dev:443` SSL, priority 1, remove completed/failed | Sonarr + Radarr agree |
| Download client | Category `books` for both audiobooks and eBooks | Matches the existing SAB category |
| Remote path mapping | `/data/usenet/complete/` → `/mnt/arrdata/usenet/complete/` | Same as Sonarr + Radarr; SAB sees the share at `/data` |
| Indexers | Synced from Prowlarr (full sync) | Registered in Prowlarr as a **Readarr**-type app — Prowlarr has no Chaptarr type, and Chaptarr keeps Readarr's `/api/v1` |

The SABnzbd API key is not in Git; it was copied from `notifiarr-secret`
(`DN_SABNZBD_0_API_KEY`).

Unlike Sonarr and Radarr, Chaptarr ties each remote path mapping to a
`downloadClientId` rather than only a host, so the mapping must be recreated if
the SABnzbd client is ever deleted and re-added.

The library was started empty on 2026-10-16. The previous contents — a Calibre
library in `ebooks/` and five eBooks misfiled under `audiobooks/` — were
deleted.

## Notes

- Chaptarr keeps Readarr's .NET options surface under the `Chaptarr:` config
  section, so environment variables use the `CHAPTARR__SECTION__KEY` form.
- The image's entrypoint drops privileges with `gosu` when started as root, but
  also supports running as an already-unprivileged user — it only needs `/config`
  to be writable, which `fsGroup: 100` provides.
- The image bundles `m4b-tool`, `mp4v2` and PHP for audiobook chapter handling.
- Unlike Sonarr and Radarr there is no `LOG__DBENABLED` option: this fork's
  `LogOptions` has no such property, so the log database is always created and
  setting the variable has no effect.
## Why Postgres

Chaptarr ran on SQLite on the `nfs-slow` config PVC first, and it did not work.
The first start failed outright with `SQLite Error 14: 'unable to open database
file'` while creating `logs.db`. After it came up and root folders were added,
every database-backed API call took 50-60s (`rootfolder` returned 200 after 55s,
`system/status` timed out at 60s) while the process sat idle at 4m CPU, and
`chaptarr.db-wal` grew to 4.3MB against a 1.5MB database without checkpointing
— lock contention, not throughput. The internal gateway times out at 15s, so
the UI was unusable. Moving main/log/cache to the PG17 cluster fixes this.

`staging.db` cannot move: `StagingDbContext` hardcodes SQLite at
`AppDataFolder/staging.db` with no Postgres branch. It stays on the config PVC.
It is small and low-traffic, and upstream describes it as "durable but
disposable".

## Database ownership caveat

The `crunchy-userinit-controller` only reassigns ownership of the single
database named in the pguser secret's `dbname` key, which is the first entry in
the cluster's `databases` list — so only `chaptarr-main` is handled
automatically. `chaptarr-log` and `chaptarr-cache` are created owned by
`postgres`, and because `public` is owned by `pg_database_owner`, the `chaptarr`
role gets no `CREATE` on their public schema and migrations fail. They need a
one-off, out-of-band:

```sql
ALTER DATABASE "chaptarr-log" OWNER TO "chaptarr";
ALTER DATABASE "chaptarr-cache" OWNER TO "chaptarr";
```

This is not captured in Git and must be redone if the PG17 cluster is rebuilt.
There is no declarative alternative: the controller ships no CRDs.

## Links

- [GitHub Repository](https://github.com/Chaptarr/chaptarr)
- [Readarr documentation](https://wiki.servarr.com/readarr) (upstream; mostly applicable)
