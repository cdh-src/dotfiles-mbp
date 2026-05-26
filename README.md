# dotfiles

Personal dotfiles for macOS, managed with GNU `stow`. Also a valid target
for the [devcontainer spec](https://containers.dev/)'s
`--dotfiles-repository` flow — see [`PREREQUISITES.md`](./PREREQUISITES.md)
"Container use".

## Setup

On a fresh Mac:

1. Clone this repo somewhere (e.g. `~/code/dotfiles-mbp`).
2. Read [`PREREQUISITES.md`](./PREREQUISITES.md) to see what gets installed.
3. Optionally run `./bootstrap.sh` to install everything via Homebrew. Idempotent.
4. (Optional) Create `~/.zshsecrets` per PREREQUISITES.md §5.
5. Run `./update.sh` to symlink configs into `$HOME`.
6. Restart your shell.

In a dev container, point `devcontainer up` at this repo:

```sh
devcontainer up --workspace-folder <project> \
  --dotfiles-repository https://github.com/cdh-src/dotfiles-mbp.git
```

The CLI clones this repo into the container and runs `install.sh`, which
installs the Linux equivalents of the Brewfile (skipping host-only items),
stows configs, and pre-warms Neovim plugins + LSPs.

## On a configured machine

`./update.sh` re-stows everything. Run it after adding files to the repo.

## Layout

Each top-level directory is a stow package using the `--dotfiles` convention (`dot-foo` → `~/.foo`). See [`CLAUDE.md`](./CLAUDE.md) for the full layout convention and key wiring notes.

## Devcontainers with `dc`

`dc` is a thin wrapper around the `devcontainer` CLI that always injects
the standard mounts (Obsidian vault, host Copilot auth, gh config, shared
Copilot data dir) and points containers at this repo as their dotfiles
source. It's the entry point for running `copilot --allow-all-tools`
safely inside any project's devcontainer.

```sh
cd <project-with-.devcontainer>
dc up                # bring up with standard mounts
dc copilot           # run Copilot CLI with --allow-all-tools, inside
dc shell             # interactive login shell, inside
```

See [`dc/README.md`](./dc/README.md) for full subcommand list and the
host/container sharing model.
