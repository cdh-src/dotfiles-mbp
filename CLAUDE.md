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
./get_batt.sh      # Print current battery percentage (legacy; tmux now uses tmux/dot-config/tmux/battery.sh)
./litellm/ai_proxy.sh   # Launch the local LiteLLM proxy on 127.0.0.1:4000
```

## Key wiring to be aware of

- **Claude Code → LiteLLM proxy.** `zsh/dot-zshrc` sets `ANTHROPIC_BASE_URL=http://127.0.0.1:4000` and pins `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` to the names defined in `litellm/dot-config/litellm_config.yaml`. The proxy maps those names onto `github_copilot/...` backends. If you rename a model in the LiteLLM config you must also update the matching `ANTHROPIC_DEFAULT_*_MODEL` env var, or Claude Code will request a model the proxy doesn't expose. The proxy's `master_key` is read from `ANTHROPIC_AUTH_TOKEN` (sourced from `~/.zshsecrets`, which is not in this repo).

- **Secrets.** `~/.zshsecrets` is sourced at the end of `dot-zshrc` if present. Do not commit it; it is intentionally outside the repo.

- **Shell plugin manager.** Zsh uses Zinit, which self-installs on first shell start if missing — there is no separate bootstrap step beyond running `update.sh` and starting a new shell.

- **Neovim entry point.** `nvim/dot-config/nvim/init.lua` calls `require("config.lazy")` (lazy.nvim bootstrap); individual plugin specs live under `lua/plugins/`. `init.lua` auto-reloads itself on `:w`.

- **tmux.** Prefix is remapped to `C-a`; plugin loader is `tpack` (the final `run 'tpack init'` line must stay last).

- **tmux status bar is split across two files.** `tmux/dot-tmux.conf` holds core options + plugin loading; `tmux/dot-tmux.status.conf` (sourced from `dot-tmux.conf` just before `tpack init`) holds the status-line theme. Iterate on the status bar in the second file. A `%hidden SEP=...` variable at the top defines a separator that recolors when the prefix is held — reuse it instead of hand-coding dots.

- **tmux status helpers live in `tmux/dot-config/tmux/`** and are invoked via `#(~/.config/tmux/<script>.sh '#{pane_current_path}')` in `dot-tmux.status.conf`. Each emits empty output → the surrounding tmux conditional collapses the segment:
  - `git_branch.sh` — full git status segment ( + branch + ahead/behind/staged/unstaged/untracked/conflicts/stash with counts). Empty outside a repo.
  - `battery.sh` — Nerd Font MDI battery glyph + percent, with a separate icon family for charging vs discharging. Replaces the old `get_batt.sh` for tmux purposes; `get_batt.sh` is kept untouched in case anything else calls it.
  - `shorten_cwd.sh` — abbreviates parent dirs (`~/code/dotfiles-mbp` → `~/c/dotfiles-mbp`). Currently unused in the status bar but kept for future reuse.

- **Nord palette is duplicated across tmux + starship.** `tmux/dot-tmux.status.conf` and `starship/dot-config/starship.toml` (the `[palettes.nord]` block) both define the same hex codes. If you tweak a color, update both. The status helper scripts also embed these colors inline via `#[fg=#XXXXXX]` tags.

- **Starship `[env_var.STARSHIP_CMD_NUM]` depends on zsh.** `zsh/dot-zshrc` exports `STARSHIP_CMD_NUM=$HISTCMD` from a `precmd_functions` hook. The bracketed command number in the prompt will silently disappear if that hook is removed.

- **tmux title bar uses OSC 2.** `set-titles on` + `set-titles-string` in `dot-tmux.conf` push titles up to the outer terminal. `terminal-overrides` adds `Ts=\E]2;:fs=\E\\` because `tmux-256color`'s terminfo entry doesn't advertise title capability. Zsh sets the *pane* title (which tmux can read via `#{pane_title}`) from `set-pane-title` in `precmd_functions`.

- **Multi-byte glyph editing gotcha.** Several files in this repo contain Nerd Font and Unicode glyphs (`` U+E0A0,  U+F4C3, `` U+F444, MDI battery icons U+F0079.., `⚔` U+2694, `⚑` U+2691, etc.). The `Edit` tool occasionally drops these bytes on write. After editing, verify with `awk 'NR==N' file | od -An -tx1` or `LC_ALL=C grep -aoE` for the UTF-8 byte sequence. For surgical glyph insertion, prefer a `python3` heredoc that opens the file as bytes.
