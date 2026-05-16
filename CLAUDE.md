# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for a 16" MacBook Pro, deployed to `$HOME` via GNU `stow`.

## Layout convention (stow)

Each top-level directory is a stow "package" that mirrors a slice of `$HOME`. The repo uses stow's `--dotfiles` mode, so filenames inside packages use a `dot-` prefix in place of a leading `.`:

- `dot-zshrc` in the repo → `~/.zshrc` on disk
- `dot-config/ghostty/config.ghostty` → `~/.config/ghostty/config.ghostty`
- `dot-tmux.conf` → `~/.tmux.conf`

When adding a new config file, place it inside the appropriate package with the `dot-` prefix; `stow` will create the symlink under `$HOME` at the matching location. The `--no-folding` flag is used, so stow creates symlinks at the file level (not by folding whole directories), which lets multiple packages contribute files into the same target directory (e.g., `~/.config/`).

## Common commands

```sh
./update.sh        # Re-stow every package in the repo to $HOME (idempotent)
```

`update.sh` iterates the top-level directories and runs `stow --dotfiles --no-folding --target=$HOME <pkg>` for each. Run it after adding a new package directory or after a fresh checkout.

```sh
./get_batt.sh      # Print current battery percentage (used by status bars, etc.)
./litellm/ai_proxy.sh   # Launch the local LiteLLM proxy on 127.0.0.1:4000
```

## Key wiring to be aware of

- **Claude Code → LiteLLM proxy.** `zsh/dot-zshrc` sets `ANTHROPIC_BASE_URL=http://127.0.0.1:4000` and pins `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` to the names defined in `litellm/dot-config/litellm_config.yaml`. The proxy maps those names onto `github_copilot/...` backends. If you rename a model in the LiteLLM config you must also update the matching `ANTHROPIC_DEFAULT_*_MODEL` env var, or Claude Code will request a model the proxy doesn't expose. The proxy's `master_key` is read from `ANTHROPIC_AUTH_TOKEN` (sourced from `~/.zshsecrets`, which is not in this repo).

- **Secrets.** `~/.zshsecrets` is sourced at the end of `dot-zshrc` if present. Do not commit it; it is intentionally outside the repo.

- **Shell plugin manager.** Zsh uses Zinit, which self-installs on first shell start if missing — there is no separate bootstrap step beyond running `update.sh` and starting a new shell.

- **Neovim entry point.** `nvim/dot-config/nvim/init.lua` calls `require("config.lazy")` (lazy.nvim bootstrap); individual plugin specs live under `lua/plugins/`. `init.lua` auto-reloads itself on `:w`.

- **tmux.** Prefix is remapped to `C-a`; plugin loader is `tpack` (the final `run 'tpack init'` line must stay last).
