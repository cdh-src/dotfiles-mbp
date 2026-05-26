# devc

Host-side wrapper around the [`devcontainer`](https://containers.dev) CLI
that injects a standard set of mounts and points every container at this
dotfiles repo via `--dotfiles-repository`.

The point: run `copilot --allow-all-tools` inside the container with
confidence — the agent sees only the project workspace plus the explicit
mounts below, not the rest of your home directory.

## Files

- `dot-local/bin/devc` → `~/.local/bin/devc` — the wrapper.
- `dot-config/devc/mounts.conf` → `~/.config/devc/mounts.conf` — the
  standard-mounts list. One `--mount` value per line; `$VAR` is expanded
  (including `$DEVC_CONTAINER_USER` / `$DEVC_CONTAINER_HOME`, see below).

## Container user

`devcontainer --mount` takes static strings — no container-side env
expansion at mount time — so `devc` must know the container user's home
path host-side. Resolution order on every `devc up`:

1. `$DEVC_CONTAINER_USER` (explicit override; export before `devc up`).
2. `mergedConfiguration.remoteUser` from `devcontainer read-configuration`.
3. `mergedConfiguration.containerUser`.
4. `vscode` (fallback).

`$DEVC_CONTAINER_HOME` is then derived: `root` → `/root`, anything else →
`/home/$user`. Override directly with `$DEVC_CONTAINER_HOME` if your image
uses a non-standard home. Both vars are exported into `mounts.conf`'s
expansion environment — reference them as `${DEVC_CONTAINER_HOME}` in
mount targets.

## Subcommands

| Command | What it does |
|---------|--------------|
| `devc up` | `devcontainer up` with standard mounts + dotfiles repo. |
| `devc rebuild` | Same, plus `--remove-existing-container`. |
| `devc down` | Stop the container (`docker stop` by id). |
| `devc shell` | Open an interactive login shell inside. |
| `devc exec ARGS…` | One-off command inside. |
| `devc copilot ARGS…` | `copilot --allow-all-tools ARGS…` inside. |
| `devc status` | Running state, image, mounts. |
| `devc logs` | `docker logs -f` the container. |
| `devc config` | Resolved devcontainer config. |

Run any of these from anywhere inside the project tree — `devc` walks up
from `$PWD` to find the nearest `.devcontainer/`. Override with
`--workspace-folder PATH`.

## Why no auto-up?

`devc shell` / `devc copilot` / `devc exec` deliberately do NOT start the
container if it's down. Starting a container is slow and may rebuild —
you should explicitly choose to do that with `devc up`. If the container
isn't running, the underlying `devcontainer exec` errors loudly.

## Prereqs

- [`devcontainer` CLI](https://github.com/devcontainers/cli) (installed
  via `bootstrap.sh` as `npm install -g @devcontainers/cli`)
- A container runtime (OrbStack on macOS recommended; Docker Desktop or
  Colima also work)
- Host paths referenced in `mounts.conf` should exist:
  `~/Documents/obsidian-notes`, `~/.copilot`, `~/.copilot-devcontainer`,
  `~/.config/gh`. `bootstrap.sh` creates `~/.copilot-devcontainer`.

## Container-side wiring

The container half lives in the repo's top-level `install.sh`, which the
devcontainer CLI runs after cloning this repo into the container via
`--dotfiles-repository`. When `install.sh` sees `~/.copilot-host`
mounted, it:

1. `npm install -g @github/copilot` (Copilot CLI inside the container)
2. Symlinks `~/.copilot/{config.json, settings.json, skills,
   session-store.db}` → `~/.copilot-host/$name` (host auth + skills,
   read-only)
3. Symlinks `~/.copilot/{session-state, command-history-state.json,
   permissions-config.json, logs}` → `~/.copilot-shared/$name`
   (read/write, shared across all containers)
4. Stubs `~/.copilot/mcp.json` if missing.
