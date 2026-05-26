# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles for macOS, deployed to `$HOME` via GNU `stow`. The repo name still mentions `mbp` for historical reasons, but the configs are written to work on any modern Mac (Apple Silicon or Intel) after the prerequisites are installed.

### Why stow (and not chezmoi/yadm)

Considered and deliberately not adopted:

- **chezmoi** — gives templating, native secrets, and per-host config. Overkill here: there's only one machine, the Nord palette duplication is small and policed by `scripts/lint-palette.sh`, and the `~/.zshsecrets` hook is enough for machine-local env vars. The "everything is a symlink you can `ls -l`" simplicity of stow is a feature worth keeping. Revisit chezmoi if multiple machines start needing meaningfully different configs.
- **yadm / bare git** — same trade-offs as stow plus less obvious file mapping.

## Prerequisites & bootstrapping

Before `./update.sh` will produce a working environment on a fresh machine, the tools, fonts, and secrets listed in **`PREREQUISITES.md`** must be installed. Read that file first.

`./bootstrap.sh` automates the brew installs listed there (via a `Brewfile` consumed by `brew bundle`). It's intentionally NOT invoked by `update.sh` — run it explicitly only after reviewing the prerequisites doc.

For use inside a devcontainer, the entry point is `./install.sh` instead — see [`PREREQUISITES.md`](./PREREQUISITES.md) "Container use" for what it does and how to invoke `devcontainer up --dotfiles-repository`. `bootstrap.sh` stays macOS-only.

> **Keep PREREQUISITES.md, `Brewfile`, `bootstrap.sh`, and `install.sh` in sync.** When any change to this repo introduces a new external dependency, update the right file(s) in the same commit: brew-installable mac items go in `Brewfile`, non-brew mac items (uv tools, manual steps) go in `bootstrap.sh`, container-required items go in the matching apk/apt list in `install.sh`, and all of them get a row in `PREREQUISITES.md`. The doc is the source of truth. `brew bundle check --file=./Brewfile` validates the brew portion against the installed state. Claude must follow this rule whenever it observes or makes such a change, even when the change is small.

## Layout convention (stow)

Each top-level directory is a stow "package" that mirrors a slice of `$HOME`. The repo uses stow's `--dotfiles` mode, so filenames inside packages use a `dot-` prefix in place of a leading `.`:

- `dot-zshrc` in the repo → `~/.zshrc` on disk
- `dot-zprofile` → `~/.zprofile`
- `dot-config/ghostty/config.ghostty` → `~/.config/ghostty/config.ghostty`
- `dot-tmux.conf` → `~/.tmux.conf`

When adding a new config file, place it inside the appropriate package with the `dot-` prefix; `stow` will create the symlink under `$HOME` at the matching location. The `--no-folding` flag is used, so stow creates symlinks at the file level (not by folding whole directories), which lets multiple packages contribute files into the same target directory (e.g., `~/.config/`).

## Common commands

```sh
./bootstrap.sh     # One-time: brew-install everything PREREQUISITES.md describes (idempotent)
./update.sh        # Re-stow every package in the repo to $HOME (idempotent)
```

`update.sh` iterates the top-level directories and runs `stow -R --dotfiles --no-folding --target=$HOME <pkg>` for each (the `-R` restows, so renamed or removed files don't leave dangling symlinks in `$HOME`). It exits non-zero if any stow invocation fails. Run it after adding a new package directory or after a fresh checkout.

Top-level directories are auto-discovered as stow packages. Add non-package dirs (e.g. `scripts/`) to the `STOW_IGNORE` set at the top of `update.sh`.

**Retiring a package.** Stow cannot unstow what no longer exists in the source tree. To remove a package cleanly, run `stow -D --dotfiles --no-folding --target=$HOME <pkg>` first, then delete the package directory.

## Key wiring to be aware of

- **Secrets.** `~/.zshsecrets` is sourced at the end of `dot-zshrc` if present. Do not commit it; it is intentionally outside the repo. The repo currently has no required secrets — the hook exists so machine-local env vars can be added without committing them.

- **Shell plugin manager.** Zsh uses Zinit, which self-installs on first shell start if missing — there is no separate bootstrap step beyond running `update.sh` and starting a new shell.

- **Neovim entry point.** `nvim/dot-config/nvim/init.lua` calls `require("config.lazy")` (lazy.nvim bootstrap); individual plugin specs live under `lua/plugins/`. `init.lua` auto-reloads itself on `:w`.

- **tmux.** Prefix is remapped to `C-a`; plugin loader is `tpack` (the final `run 'tpack init'` line must stay last).

- **tmux status bar is split across two files.** `tmux/dot-tmux.conf` holds core options + plugin loading; `tmux/dot-tmux.status.conf` (sourced from `dot-tmux.conf` just before `tpack init`) holds the status-line theme. Iterate on the status bar in the second file. A `%hidden SEP=...` variable at the top defines a separator that recolors when the prefix is held — reuse it instead of hand-coding dots.

- **tmux status helpers live in `tmux/dot-config/tmux/`** and are invoked via `#(~/.config/tmux/<script>.sh '#{pane_current_path}')` in `dot-tmux.status.conf`. Each emits empty output → the surrounding tmux conditional collapses the segment:
  - `git_branch.sh` — full git status segment ( + branch + ahead/behind/staged/unstaged/untracked/conflicts/stash with counts). Empty outside a repo.
  - `battery.sh` — Nerd Font MDI battery glyph + percent, with a separate icon family for charging vs discharging.

- **Devcontainer wrapper (`devc`).** The `devc/` stow package ships `~/.local/bin/devc` (bash wrapper around the `devcontainer` CLI) and `~/.config/devc/mounts.conf` (line-per-mount config, env-expanded by the wrapper). `devc up` always injects the standard mounts plus `--dotfiles-repository` pointing at this repo. The container user is auto-resolved host-side on every `devc up` (priority: `$DEVC_CONTAINER_USER` env > `mergedConfiguration.remoteUser` > `mergedConfiguration.containerUser` > fallback `vscode`) and exported as `$DEVC_CONTAINER_USER` + `$DEVC_CONTAINER_HOME` (`/root` for root, else `/home/$user`) into `mounts.conf`'s expansion env — so mount targets like `${DEVC_CONTAINER_HOME}/.copilot-host` resolve correctly per image, instead of being hardcoded. The container-side install logic in `install.sh` (after stowing) detects the `~/.copilot-host` bind mount, installs `@github/copilot` via npm, and creates symlinks: host auth/skills/session-store.db symlinked from `~/.copilot-host/` (mount is rw because devcontainer CLI rejects `readonly`; Copilot never writes back through these paths, so host data is safe in practice), and writable cross-container state (session-state, command history, permissions, logs) from `~/.copilot-shared/` (host `~/.copilot-devcontainer/`). install.sh is fully `$HOME`-based, so the symlink wiring is naturally user-agnostic. The `devc` package itself is in install.sh's `STOW_SKIP` so it doesn't get stowed inside containers.

- **Obsidian vault inside containers.** Two mechanisms point Obsidian-aware tools at the bind-mounted vault: (1) `zsh/dot-zshenv` exports `OBSIDIAN_VAULT=/obsidian` when `/.dockerenv` exists (covers any in-container zsh session, including `devc shell`); (2) `devc` itself injects `--remote-env OBSIDIAN_VAULT=/obsidian` on `shell`/`exec`/`copilot` subcommands so non-shell processes (notably the `copilot` Node binary) see it too. The `obsidian-*` Copilot skills check `$OBSIDIAN_VAULT` first, so they "just work" inside containers without falling back to the host-only `~/Documents/obsidian-notes` path. Copilot permissions don't carry over from host: the container's permission file is the shared `~/.copilot-shared/permissions-config.json` (host `~/.copilot-devcontainer/permissions-config.json`), distinct from the host's `~/.copilot/permissions-config.json`. Run `/add-dir /obsidian` once inside any container; the grant then persists across every future container.

- **Nord palette is deliberately duplicated across tmux, starship, and lualine.** `tmux/dot-tmux.status.conf`, `tmux/dot-config/tmux/git_branch.sh`, `starship/dot-config/starship.toml` (the `[palettes.nord]` block), and `nvim/dot-config/nvim/lua/plugins/lualine.lua` (the `local nord = {...}` table) all define the same hex codes. This is a deliberate trade-off — ten stable hex codes do not warrant a templating/build step. `scripts/lint-palette.sh` is the drift detector: it asserts every hex in those consumers is in the canonical Nord set, and that every canonical color is used by someone. Run it (or `scripts/lint.sh`) after touching any colored config.

- **Starship `[env_var.STARSHIP_CMD_NUM]` depends on zsh.** `zsh/dot-zshrc` exports `STARSHIP_CMD_NUM=$HISTCMD` from a `precmd_functions` hook. The bracketed command number in the prompt will silently disappear if that hook is removed.

- **tmux title bar uses OSC 2.** `set-titles on` + `set-titles-string` in `dot-tmux.conf` push titles up to the outer terminal. `terminal-overrides` adds `Ts=\E]2;:fs=\E\\` because `tmux-256color`'s terminfo entry doesn't advertise title capability. Zsh sets the *pane* title (which tmux can read via `#{pane_title}`) from `set-pane-title` in `precmd_functions`.

- **Portability.** No file in the repo hardcodes `/Users/chartwig` or `/opt/homebrew`. `zsh/dot-zprofile` probes both `/opt/homebrew/bin/brew` and `/usr/local/bin/brew` to pick the right Homebrew prefix (Apple Silicon vs Intel). All user-relative paths use `$HOME`. If you add a new path or brew prefix assumption, follow the same pattern.

- **Multi-byte glyph editing gotcha.** Several files in this repo contain Nerd Font and Unicode glyphs (`` U+E0A0,  U+F4C3, `` U+F444, MDI battery icons U+F0079.., `⚔` U+2694, `⚑` U+2691, etc.). The `Edit` tool occasionally drops these bytes on write. After editing, verify with `awk 'NR==N' file | od -An -tx1` or `LC_ALL=C grep -aoE` for the UTF-8 byte sequence. For surgical glyph insertion, prefer a `python3` heredoc that opens the file as bytes.
