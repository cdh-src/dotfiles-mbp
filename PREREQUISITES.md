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

## Keeping this file in sync

If you add a new external dependency to any config, update the right file:

- **Brew-installable** (formula, tap, cask, font cask) → add a line to [`Brewfile`](./Brewfile) and a row to the relevant table above.
- **Not brew-installable** (uv tool, manual step) → add it to `bootstrap.sh` and the table above.

`brew bundle check --file=./Brewfile` is the drift test for the brew portion. CLAUDE.md restates this rule for any future automated changes.
