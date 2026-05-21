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
| **git** | Stow doesn't need it, but Zinit and lazy.nvim self-bootstrap by cloning their repos on first run. | Comes with Xcode CLT (`xcode-select --install`) or `brew install git`. |
| **GNU stow** | `update.sh` is a stow wrapper; needs the `--dotfiles` flag (stow ≥ 2.3.1, 2015). | `brew install stow` |
| **zsh** | The default macOS login shell since Catalina; `update.sh` and `dot-zprofile` use zsh idioms (`${0:A:h}`, glob qualifiers). | Pre-installed on modern macOS. If absent: `brew install zsh`. |

## 2. Tools used by configs

Without these, parts of the prompt/status bar/editor go silent or error.

| Tool | Used by | Install |
|------|---------|---------|
| **tmux** | `tmux/dot-tmux.conf` | `brew install tmux` |
| **tpack** | `tmux/dot-tmux.conf` runs `tpack init` to load tmux plugins (nord-tmux, tmux-sensible, vim-tmux-navigator). | `brew install tmuxpack/tpack/tpack` |
| **starship** | The shell prompt (`zsh/dot-zshrc` calls `starship init zsh`). | `brew install starship` |
| **neovim** | `nvim/dot-config/nvim/`. `init.lua` is the entry point; lazy.nvim self-bootstraps from git on first run. | `brew install neovim` |
| **ghostty** | `ghostty/dot-config/ghostty/config.ghostty` | `brew install --cask ghostty` |
| **lsd** | `alias ls=lsd` in `dot-zshrc`. Without it, every `ls` errors. | `brew install lsd` |
| **zoxide** | Loaded as a Zinit plugin in `dot-zshrc`. Provides smarter `cd`. | `brew install zoxide` |
| **uv** | Python toolchain manager used to install LiteLLM in an isolated venv pinned to a specific Python version. | `brew install uv` |
| **litellm** | `litellm/ai_proxy.sh` launches a LiteLLM server that fronts the GitHub Copilot Claude models for Claude Code. The `[proxy]` extras (uvicorn, fastapi, etc.) are required for the server. **Pin Python to 3.13** — some of LiteLLM's proxy dependencies have lagged on newer Python versions and produce import errors otherwise. | `uv tool install --python 3.13 'litellm[proxy]'` |
| **python3** | Used directly by a few small helper scripts. | Pre-installed on modern macOS; otherwise `brew install python3`. |

## 3. Fonts

| Font | Why | Install |
|------|-----|---------|
| **0xProto Nerd Font** | Set as `font-family` in `ghostty/dot-config/ghostty/config.ghostty`. Also: the tmux status bar uses Nerd Font Material Design Icons (battery, git glyphs) and Powerline glyphs (` `). Without a Nerd Font, all of those render as tofu. | `brew install --cask font-0xproto-nerd-font` |

## 4. Plugin managers

These self-bootstrap from inside the configs — you don't install them yourself, but they need `git` and network access on first run.

| Manager | Where | Bootstrap behavior |
|---------|-------|-------------------|
| **Zinit** (zsh) | Top of `zsh/dot-zshrc` | Clones itself into `~/.local/share/zinit/zinit.git` on first shell start. |
| **lazy.nvim** | `nvim/dot-config/nvim/lua/config/lazy.lua` | Clones itself into `~/.local/share/nvim/lazy/lazy.nvim` on first nvim launch. |
| **tpack** (tmux) | Brew-installed (see §2). `dot-tmux.conf`'s final `run 'tpack init'` line then loads it on every tmux start. |

After everything's installed, the first launch of each tool may take a minute while plugins clone.

## 5. Secrets file

`zsh/dot-zshrc` sources `~/.zshsecrets` if present. This file is **intentionally outside the repo** — never commit it.

At minimum it must export:

```zsh
# ~/.zshsecrets
export ANTHROPIC_AUTH_TOKEN='paste-litellm-master-key-here'
```

`ANTHROPIC_AUTH_TOKEN` is consumed by:
- `litellm/dot-config/litellm_config.yaml` as the LiteLLM proxy's `master_key`.
- Claude Code, which uses the same token to talk to the proxy at `http://127.0.0.1:4000`.

Pick any random string for the value — it's a shared secret between Claude Code and the LiteLLM proxy running locally on the same machine. The proxy doesn't validate it against an external service.

For LiteLLM to talk to GitHub Copilot's backend, you'll also need a Copilot subscription with the relevant Claude models available. LiteLLM handles the underlying GitHub auth flow itself the first time it runs.

## 6. Manual post-install

A few things `bootstrap.sh` and `update.sh` can't do for you:

1. **Set Ghostty as the default terminal.** Open Ghostty, then in System Settings (or the Ghostty menu) make it the default.
2. **Accessibility permission** if you use the vim-tmux-navigator key chord through `C-h/j/k/l` and it doesn't work — macOS may prompt for accessibility access for Ghostty.
3. **Sign in to GitHub Copilot** the first time LiteLLM proxies a request. LiteLLM will print a device-flow URL to the terminal.
4. **Run `./update.sh`** to stow all the config files into `$HOME`.
5. **Restart your shell** so `dot-zprofile` (Homebrew shellenv) and `dot-zshrc` (Zinit, starship, vi mode) all take effect.

---

## Keeping this file in sync

If you add a new external dependency to any config (a new brew formula, a new font, a new tmux plugin, a new shell tool), update both **this file** and **`bootstrap.sh`** in the same commit. The two are meant to be reviewable against each other. CLAUDE.md restates this rule for any future automated changes.
