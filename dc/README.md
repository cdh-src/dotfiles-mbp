# dc

Host-side wrapper around the [`devcontainer`](https://containers.dev) CLI
that injects a standard set of mounts and points every container at this
dotfiles repo via `--dotfiles-repository`.

The point: run `copilot --allow-all-tools` inside the container with
confidence — the agent sees only the project workspace plus the explicit
mounts below, not the rest of your home directory.

## Files

- `dot-local/bin/dc` → `~/.local/bin/dc` — the wrapper.
- `dot-config/dc/mounts.conf` → `~/.config/dc/mounts.conf` — the
  standard-mounts list. One `--mount` value per line; `$VAR` is expanded.

## Subcommands

| Command | What it does |
|---------|--------------|
| `dc up` | `devcontainer up` with standard mounts + dotfiles repo. |
| `dc rebuild` | Same, plus `--remove-existing-container`. |
| `dc down` | Stop the container (`docker stop` by id). |
| `dc shell` | Open an interactive login shell inside. |
| `dc exec ARGS…` | One-off command inside. |
| `dc copilot ARGS…` | `copilot --allow-all-tools ARGS…` inside. |
| `dc status` | Running state, image, mounts. |
| `dc logs` | `docker logs -f` the container. |
| `dc config` | Resolved devcontainer config. |

Run any of these from anywhere inside the project tree — `dc` walks up
from `$PWD` to find the nearest `.devcontainer/`. Override with
`--workspace-folder PATH`.

## Why no auto-up?

`dc shell` / `dc copilot` / `dc exec` deliberately do NOT start the
container if it's down. Starting a container is slow and may rebuild —
you should explicitly choose to do that with `dc up`. If the container
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
