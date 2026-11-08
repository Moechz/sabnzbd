# sabnzbd-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [SABnzbd](https://github.com/sabnzbd/sabnzbd).

## What this is

A four-file TOS Docker application archive (`sabnzbddocker.tar.gz`) that installs
SABnzbd on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `sabnzbddocker`)
- `sabnzbddocker.lang` — 23-language superset (TOS requires 14)
- `sabnzbddocker.svg` — application icon (594 bytes, 1 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/sabnzbd:5.1.3`

## How it works

| | |
|---|---|
| Container image | `linuxserver/sabnzbd:5.1.3` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8007/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/sabnzbddocker/config`, `/downloads` → `/Volume1/DockerAppData/sabnzbddocker/downloads` |
| Logs | `docker logs sabnzbddocker` (stdout/stderr) |

`config/` holds `sabnzbd.ini` (server, provider, folders, categories), the web UI cache (`admin/`), logs and - by default - a `Downloads/` folder for finished files. `downloads/` is the `/downloads` volume: point SABnzbd's complete folder there to keep downloads out of the config directory. Copying the `sabnzbddocker` folder is a complete backup.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper** (not a privilege shim): the s6 service manager of the image needs root, so `src/entrypoint.sh` starts SABnzbd directly as the unprivileged container user.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Non-root by construction.** The s6 service manager of the image runs as root, so the wrapper starts SABnzbd directly as `1000:1000`; verified on real hardware with `id` inside the container.
- **Fixed image tag `5.1.3`**, Docker Hub only, no `privileged`, no `network_mode: host`, no `cap_add`, no Docker socket.
- **Health check** on the UI itself (`GET /` on port 8080) with a 90 s start period for the first start.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config/sabnzbd.ini` | all settings - Usenet servers, folders, categories, API key, web UI options | first start | static, rewritten on every settings change | never overwritten by the app; it is the whole configuration |
| `config/logs` | SABnzbd log files | first start | rotated by SABnzbd | safe to delete |
| `config/admin` | web UI cache and the .rss/.nzb admin area | first start | small | safe to delete |
| `config/Downloads` | default complete-download folder (SABnzbd's default is relative to the config directory) | first start | grows with every download until you move the files out | managed by SABnzbd and by you |
| `downloads` | the /downloads volume - set it as the complete folder in the web UI to keep downloads there | first start (empty) | grows with every download | managed by you |

## Build

```bash
scripts/build.sh                  # -> out/sabnzbddocker.tar.gz + .sha256
scripts/build.sh 5.1.3-2   # packaging iteration bump
scripts/build.sh 5.1.3-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/sabnzbddocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v5.1.3-1`**, assets `sabnzbddocker.tar.gz` +
   `sabnzbddocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `sabnzbddocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `5.1.3-1` → automated validation → review.

## License / branding

SABnzbd is distributed by its upstream authors under **GPL-2.0**. The container image is the official image from Docker Hub (`linuxserver/sabnzbd:5.1.3`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

TOS Docker applications cannot mount shared folders: finished downloads stay in `/Volume1/DockerAppData/sabnzbddocker/downloads/`. Move them to your media share with File Manager, or edit `/Volume1/@apps/DockerEngine/application/sabnzbddocker/docker-compose.yml` after installation to mount a share.
A Usenet provider account is required; indexers and the *arr integration are optional and configured in the web UI.
The UI is served over plain HTTP on the LAN. Do not expose the published port to the internet without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
