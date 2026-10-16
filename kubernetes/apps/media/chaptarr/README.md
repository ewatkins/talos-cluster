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
| Config PVC | `chaptarr-config`, 10Gi (`nfs-slow`) | Mounted at `/config` |
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

These must be set in the UI on first run; they are not part of the manifests.

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
- Chaptarr keeps three SQLite databases in `/config` — `chaptarr.db` (WAL),
  plus `logs.db` and `cache.db` (rollback journal). The journal-mode databases
  are the weak point on NFS: the first start here failed with
  `SQLite Error 14: 'unable to open database file'` creating `logs.db`, and
  succeeded on the retry. If that recurs, the fix is to move the databases to
  the cluster's Postgres via `CHAPTARR__POSTGRES__*` rather than to fight NFS
  locking.

## Links

- [GitHub Repository](https://github.com/Chaptarr/chaptarr)
- [Readarr documentation](https://wiki.servarr.com/readarr) (upstream; mostly applicable)
