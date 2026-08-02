# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a Home Assistant add-on repository (see `repository.yaml`) that aggregates multiple add-ons. Each top-level directory is one add-on and follows the standard HA add-on layout (`config.yaml`, `Dockerfile`, `build.yaml`, `rootfs/`).

Most add-ons are **git submodules** pointing to their own repos (see `.gitmodules`):
- `voltronic/` — inverter monitoring, own repo
- `ntfy/` — ntfy push notification server, own repo
- `hassio-addons-prowlarr/`, `hassio-addons-radarr/`, `hassio-addons-sonarr/` — forks of `hassio-addons/app-*`; the actual add-on lives in a nested `prowlarr/`, `radarr/`, `sonarr/` subdirectory

In-tree add-ons (not submodules): `doods2/`, `jakett/`.

When editing a submodule, changes must be committed inside that submodule's repo; a superproject commit only bumps the submodule pointer. To sync submodules after pulling: `git submodule update --init --recursive`.

## Add-on structure conventions

- `config.yaml` — HA add-on manifest (name, version, slug, arch list, ports, schema/options, `build_from` base images per arch).
- `build.yaml` — per-arch base image overrides + OCI labels (only when needed; some add-ons keep `build_from` inside `config.yaml`).
- `Dockerfile` — takes `BUILD_FROM` ARG; copies `rootfs/` into `/`; typically uses s6-overlay (`ENTRYPOINT ["/init"]`) for service supervision.
- `rootfs/etc/services.d/<name>/run` (or `rootfs/etc/s6-overlay/s6-rc.d/<name>/run`) — the actual service entrypoint. Reads config via `bashio::config 'key'` (from `/usr/bin/with-contenv bashio` shebang) and execs the app.

The `*arr` submodules use the newer `s6-rc.d` layout; `voltronic` uses the legacy `services.d` layout — copy the pattern already present in the add-on you're modifying rather than mixing them.

## Voltronic add-on specifics

Voltronic is the only add-on with non-trivial custom source. It ships:
1. `src/inverter-cli/` — C++ tool (CMake, C++11, static build). Built in a Docker multi-stage `build` stage: `cmake -Bbuild -H. && cmake --build build && cmake --install build` → binary lands at `/opt/inverter-cli/bin/inverter_poller`.
2. `src/mqtt-init.sh` / `src/mqtt-push.sh` — bash scripts installed to `/opt/inverter-mqtt/`. `mqtt-init.sh` publishes MQTT discovery topics once at startup; `mqtt-push.sh` is called every `run_interval` seconds by the s6 `run` script and shells out to `inverter_poller` to read the inverter, then publishes state via `mosquitto_pub`.
3. `src/rootfs/etc/services.d/inverter/run` — reads add-on options with `bashio::config`, writes `/etc/inverter/inverter.conf`, then loops `mqtt-push.sh; sleep $RUN_INTERVAL`.

When adding a new inverter query (QPIRI/QPIWS/QMOD/QPIGS pattern), the length must be plumbed through the schema in `config.yaml`, the `bashio::config` block in the `run` script, and the `inverter.conf` written by that script — the C++ binary reads that config file, not env vars.

## Devcontainer

`.devcontainer.json` launches the official HA supervisor devcontainer (`ghcr.io/home-assistant/devcontainer:addons`) with docker-in-docker. `postStartCommand` runs `bash script/setup` (which the HA base image provides). Forwarded ports: 8123 (HA UI), 4357 (observer). Inside the container the HA supervisor can install any add-on from this repo directly for testing.

## CI

The `*arr` submodules inherit CI from `hassio-addons/workflows/.github/workflows/app-ci.yaml` (see each submodule's `.github/workflows/ci.yaml`). This runs shellcheck, hadolint, yamllint, markdownlint, and multi-arch Docker builds. The in-tree add-ons and `voltronic`/`ntfy` don't have their own CI in this superproject — validate locally with the linters those workflows use.
