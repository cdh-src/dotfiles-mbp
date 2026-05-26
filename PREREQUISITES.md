# Prerequisites

What you need installed before `./update.sh` (and the configs it deploys) will
work end-to-end on a fresh Mac. Read this through once; then decide whether to
run `./bootstrap.sh` (which automates the brew installs below) or do it by hand.

`bootstrap.sh` is intentionally separate from `update.sh` so you can review
this list first. Anything mentioned here must also appear in `bootstrap.sh` —
they're meant to stay in lock-step.

---

## 1. Hard requirements

Without these, `./update.sh` fails or core configs don't load.

| Tool | Why | Install |
|------|-----|---------|
| **Homebrew** | Everything else installs through it. | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| **git** | Stow doesn't need it, but Zinit and lazy.nvim self-bootstrap by cloning their repos on first run. | via `brew bundle` (see [`Brewfile`](./Brewfile)). |
| **GNU stow** | `update.sh` is a stow wrapper; needs the `--dotfiles` flag (stow ≥ 2.3.1, 2015). | via `brew bundle`. |
| **zsh** | The default macOS login shell since Catalina; `update.sh` and `dot-zprofile` use zsh idioms (`${0:A:h}`, glob qualifiers). | Pre-installed on modern macOS. `bootstrap.sh` falls back to `brew install zsh` only if `command -v zsh` reports it missing. |

## 2. Tools used by configs

Without these, parts of the prompt/status bar/editor go silent or error.

| Tool | Used by | Install |
|------|---------|---------|
| **tmux** | `tmux/dot-tmux.conf` | via `brew bundle` (see [`Brewfile`](./Brewfile)). |
| **tpack** | `tmux/dot-tmux.conf` runs `tpack init` to load tmux plugins (tmux-sensible, vim-tmux-navigator). | via `brew bundle` (taps `tmuxpack/tpack`). |
| **starship** | The shell prompt (`zsh/dot-zshrc` calls `starship init zsh`). | via `brew bundle`. |
| **neovim** | `nvim/dot-config/nvim/`. `init.lua` is the entry point; lazy.nvim self-bootstraps from git on first run. | via `brew bundle`. |
| **ghostty** | `ghostty/dot-config/ghostty/config.ghostty` | via `brew bundle` (cask). |
| **lsd** | `alias ls=lsd` in `dot-zshrc`. Without it, every `ls` errors. | via `brew bundle`. |
| **zoxide** | Loaded as a Zinit plugin in `dot-zshrc`. Provides smarter `cd`. | via `brew bundle`. |
| **python3** | Used directly by a few small helper scripts. | Pre-installed on modern macOS. `bootstrap.sh` falls back to `brew install python3` only if `command -v python3` reports it missing. |
| **shellcheck** | `scripts/lint.sh` runs it on the bash scripts (`bootstrap.sh`, lint scripts) as part of `./scripts/lint.sh`. Not required for the dotfiles to work; only needed if you run lint locally. | via `brew bundle`. |
| **node** | Runtime for the `devcontainer` and Copilot CLIs (both shipped as global npm packages). | via `brew bundle`. |
| **devcontainer CLI** | Used by the `dc` wrapper (see [`dc/README.md`](./dc/README.md)). | `bootstrap.sh` runs `npm install -g @devcontainers/cli` after `brew bundle`. |
| **Copilot CLI** | Run inside dev containers via `dc copilot`. The host copy is also handy for ad-hoc use. | `bootstrap.sh` runs `npm install -g @github/copilot` after `brew bundle`. |
| **OrbStack** *(or any container runtime)* | The `dc` wrapper needs a working Docker-compatible runtime. OrbStack is recommended on macOS — bind mounts handle uid mapping transparently between host uid 501 and container uid 1000. Docker Desktop and Colima also work. | Install separately ([orbstack.dev](https://orbstack.dev)); not in `Brewfile` to keep the install opt-in. |

## 3. Fonts

| Font | Why | Install |
|------|-----|---------|
| **0xProto Nerd Font** | Set as `font-family` in `ghostty/dot-config/ghostty/config.ghostty`. Also: the tmux status bar uses Nerd Font Material Design Icons (battery, git glyphs) and Powerline glyphs (` `). Without a Nerd Font, all of those render as tofu. | via `brew bundle` (cask). |

## 4. Plugin managers

These self-bootstrap from inside the configs — you don't install them yourself, but they need `git` and network access on first run.

| Manager | Where | Bootstrap behavior |
|---------|-------|-------------------|
| **Zinit** (zsh) | Top of `zsh/dot-zshrc` | Clones itself into `~/.local/share/zinit/zinit.git` on first shell start. |
| **lazy.nvim** | `nvim/dot-config/nvim/lua/config/lazy.lua` | Clones itself into `~/.local/share/nvim/lazy/lazy.nvim` on first nvim launch. |
| **tpack** (tmux) | Brew-installed (see §2). `dot-tmux.conf`'s final `run 'tpack init'` line then loads it on every tmux start. |

After everything's installed, the first launch of each tool may take a minute while plugins clone.

## 5. Secrets file

`zsh/dot-zshrc` sources `~/.zshsecrets` if present. The file is **intentionally outside the repo** — never commit it.

The repo currently has no required secrets; the hook is kept so you can add machine-local environment variables (API keys, tokens, machine-specific overrides) without committing them. If you don't need any, you can skip creating the file entirely.

## 6. Manual post-install

A few things `bootstrap.sh` and `update.sh` can't do for you:

1. **Set Ghostty as the default terminal.** Open Ghostty, then in System Settings (or the Ghostty menu) make it the default.
2. **Accessibility permission** if you use the vim-tmux-navigator key chord through `C-h/j/k/l` and it doesn't work — macOS may prompt for accessibility access for Ghostty.
3. **Run `./update.sh`** to stow all the config files into `$HOME`.
4. **Restart your shell** so `dot-zprofile` (Homebrew shellenv) and `dot-zshrc` (Zinit, starship, vi mode) all take effect.

---

## Container use (devcontainers)

This repo doubles as a dotfiles target for the [devcontainer
spec](https://containers.dev/)'s `--dotfiles-repository` flow. Point it at
this repo:

```sh
devcontainer up --workspace-folder <project> \
  --dotfiles-repository https://github.com/cdh-src/dotfiles-mbp.git
```

The devcontainer CLI clones this repo into the container at `~/dotfiles`
and runs the first script it finds among `install.sh` / `setup.sh` /
`bootstrap.sh`. Our `install.sh` is the container entry point —
`bootstrap.sh` stays macOS-only and is never executed inside the container.

What `install.sh` does:

1. Detects the distro (Alpine via apk, Debian/Ubuntu via apt). Other
   distros fail loudly.
2. Installs Linux equivalents of the §2 tools, plus the runtime deps that
   `mason.nvim` and `nvim-treesitter` need (nodejs/npm/unzip/tar plus a C
   toolchain). Skips host-only items: tmux, tpack, ghostty, fonts,
   shellcheck. starship comes from apk on Alpine, from the upstream
   installer script on Debian/Ubuntu (it's not in apt).
3. Backs up any pre-existing dotfiles in `$HOME` to
   `~/.pre-stow-backup-<timestamp>/`. MS's devcontainer base image ships
   `.zshrc` and `.bashrc` from oh-my-zsh; these would otherwise collide
   with our stow.
4. Runs `update.sh` with `STOW_SKIP="ghostty tmux"` so mac-only packages
   don't get stowed.
5. Pre-warms Neovim: runs `Lazy! sync` and explicitly drives the
   `mason-lspconfig` `ensure_installed` set (pyright, lua_ls, yamlls) so
   the first interactive `nvim` opens with everything ready. LSPs without
   a prebuilt for the container's platform (e.g. lua-language-server on
   Alpine musl/aarch64) are reported as `MISSING` and skipped; install
   succeeds anyway.

Tested against `ghcr.io/home-assistant/home-assistant:stable` (Alpine 3.22
aarch64) and `mcr.microsoft.com/devcontainers/base:ubuntu` (Ubuntu 26.04
aarch64). Older Ubuntu releases may not have a recent enough Neovim or
lsd/zoxide in apt — extend `install.sh` if you hit one.

Per-project Python LSP config (`pyrightconfig.json` pointing pyright at
the project's interpreter) is the project's responsibility, not this
repo's. See the relevant project's `.devcontainer/` for examples.

### The `dc` wrapper (recommended)

For day-to-day devcontainer use, the repo ships a `dc` wrapper (see
[`dc/README.md`](./dc/README.md)) that always injects:

- The Obsidian vault (`~/Documents/obsidian-notes` → `/obsidian`).
- Host Copilot auth + skills (read-only) and a cross-container Copilot
  data dir (`~/.copilot-devcontainer/`).
- The host `gh` CLI config (read-only).
- This dotfiles repo via `--dotfiles-repository`.

```sh
cd <project-with-.devcontainer>
dc up
dc copilot           # runs `copilot --allow-all-tools` inside the container
```

`bootstrap.sh` installs the devcontainer CLI and Copilot CLI (npm globals)
and creates `~/.copilot-devcontainer/`. The `dc` script and its
`mounts.conf` come from the `dc/` stow package — re-run `./update.sh`
after pulling changes to that package.

---

## Keeping this file in sync

If you add a new external dependency to any config, update the right file:

- **Brew-installable** (formula, tap, cask, font cask) → add a line to [`Brewfile`](./Brewfile) and a row to the relevant table above.
- **Not brew-installable** (uv tool, manual step) → add it to `bootstrap.sh` and the table above.
- **Needed inside dev containers too** → add it to the matching `apk`/`apt` list in [`install.sh`](./install.sh). Mention it under "Container use" above.

`brew bundle check --file=./Brewfile` is the drift test for the brew portion. CLAUDE.md restates this rule for any future automated changes.
