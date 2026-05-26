#!/bin/sh
# Container entry point for devcontainer's --dotfiles-repository flow.
# Devcontainers prefer install.sh > setup.sh > bootstrap.sh, so this wins
# automatically without touching the macOS bootstrap.sh.
#
# Detects Alpine (apk) vs Debian/Ubuntu (apt), installs the Linux equivalents
# of the host Brewfile (minus mac-only and host-only tools), then runs
# update.sh to stow configs into $HOME.
#
# Idempotent: safe to re-run. Conflicting pre-existing dotfiles in $HOME are
# moved aside into ~/.pre-stow-backup-<timestamp>/ before stowing.

set -eu

# ---- env ------------------------------------------------------------------

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)

# Use sudo only when we're not already root. Inside both target images we
# run as root, but a future non-root image (vscode user, etc.) should still
# work without changes.
if [ "$(id -u)" = 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Stow these macOS-only / host-only packages are skipped inside containers.
# update.sh reads STOW_SKIP (added in step 5b) and combines with STOW_IGNORE.
#   - ghostty, tmux: macOS-only / host-only.
#   - dc: host-side wrapper around `devcontainer` CLI. Pointless inside the
#     container it would be wrapping.
export STOW_SKIP="ghostty tmux dc"

log() { printf '  %s\n' "$*"; }
bold() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

# ---- distro detection -----------------------------------------------------

if [ ! -r /etc/os-release ]; then
  echo "error: /etc/os-release missing; cannot identify distro." >&2
  exit 1
fi
# shellcheck disable=SC1091
. /etc/os-release

case "${ID:-}${ID_LIKE:+ }${ID_LIKE:-}" in
  alpine*)         PM=apk ;;
  *debian*|*ubuntu*) PM=apt ;;
  *)
    echo "error: unsupported distro '${ID:-unknown}'. Add a branch to install.sh." >&2
    exit 1
    ;;
esac

bold "Detected: $ID $VERSION_ID ($PM)"

# ---- package install ------------------------------------------------------
#
# Common shopping list (across both PMs):
#   stow + git + zsh           -> required to run update.sh and use the shell
#   neovim + ripgrep + fd      -> editor and its search helpers
#   starship + lsd + zoxide    -> prompt and zsh-aliased tools
#   nodejs + npm + unzip + tar -> mason runtime deps (LSP installers use them)
#   build-base/build-essential -> nvim-treesitter compiles parsers from C
#   curl + ca-certificates     -> starship (apt path) and general fetching
#
# Skipped: tmux, tpack, ghostty, fonts, shellcheck (host-only or irrelevant).
# LSPs: NOT installed here. mason-lspconfig ensure_installed handles those
# on first nvim launch (pre-warmed below).

bold "Installing system packages"

case "$PM" in
  apk)
    $SUDO apk update
    # Alpine has starship and fd directly; everything we need in main+community.
    $SUDO apk add --no-progress \
      git zsh stow neovim \
      starship lsd zoxide ripgrep fd \
      nodejs npm unzip tar ca-certificates curl \
      build-base
    ;;
  apt)
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update -qq
    # Ubuntu 26.04+ has modern neovim, lsd, zoxide in apt. Older releases
    # may not — if you see "Unable to locate package", add a release-pin or
    # fall back to a binary install.
    $SUDO apt-get install -y --no-install-recommends \
      git zsh stow neovim \
      lsd zoxide ripgrep fd-find \
      nodejs npm unzip tar ca-certificates curl \
      build-essential

    # starship: not in apt. Use upstream installer script. -y skips its prompt.
    if ! command -v starship >/dev/null 2>&1; then
      log "installing starship from upstream script…"
      curl -fsSL https://starship.rs/install.sh | $SUDO sh -s -- -y >/dev/null
    fi

    # Debian/Ubuntu ship the fd binary as `fdfind`. zshrc aliases ls=lsd and
    # plugins/tooling expect `fd`. Add a user-local symlink; dot-zshenv
    # already prepends ~/.local/bin to PATH.
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/bin"
      ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    ;;
esac

# ---- pre-stow conflict handling -------------------------------------------
#
# Some base images (MS devcontainers/base:ubuntu ships oh-my-zsh) seed
# $HOME with .zshrc / .bashrc / .gitconfig. Stow will refuse to clobber
# real files. Move conflicts aside so re-running install.sh is safe.

bold "Backing up pre-existing dotfiles (if any)"

ts=$(date -u +%Y%m%dT%H%M%SZ)
backup="$HOME/.pre-stow-backup-$ts"
moved=0
# Files we know we stow. Keep in lock-step with the dot- prefixed files in
# the stow packages we deploy to containers.
for f in .zshrc .zshenv .zprofile .bashrc .gitconfig .hushlogin; do
  src="$HOME/$f"
  # Real file (not a symlink we already own) → move aside.
  if [ -e "$src" ] && [ ! -L "$src" ]; then
    [ "$moved" = 0 ] && mkdir -p "$backup"
    mv "$src" "$backup/"
    log "backed up: $f -> $backup/"
    moved=1
  fi
done
[ "$moved" = 0 ] && log "(none)"

# ---- stow --------------------------------------------------------------------

bold "Stowing dotfiles (STOW_SKIP=\"$STOW_SKIP\")"
zsh "$script_dir/update.sh"

# ---- nvim pre-warm: install plugins + mason LSPs ---------------------------
#
# First nvim launch otherwise eats 60-120s while lazy.nvim clones plugins and
# mason-lspconfig kicks off pyright/lua_ls/yamlls. Doing it now means the
# user's first nvim opens instantly.
#
# Two phases:
#   1. +Lazy! sync — clone/install all plugins synchronously.
#   2. vim.wait loop — give mason-lspconfig.ensure_installed time to finish
#      (async; the wait polls mason-registry until all three are installed).
# A 5-minute cap keeps install.sh from hanging on a flaky network.

bold "Pre-warming Neovim (plugins + LSPs)"

nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || log "lazy sync had warnings (continuing)"

# Explicitly drive mason. `+Lazy! sync` installs plugins but lazy.nvim does
# not LOAD them until triggered, so mason-lspconfig's ensure_installed never
# fires in a headless pre-warm. Iterate the registry by mason package names
# (note: mason names differ from lspconfig server names — e.g. "lua_ls" is
# "lua-language-server"), trigger install() on any missing package, then
# vim.wait for completion (5-minute cap so flaky networks don't hang us).
prewarm_lua=$(mktemp /tmp/prewarm.XXXXXX)
cat > "$prewarm_lua" <<'LUA'
require("mason")
local r = require("mason-registry")
local wanted = { "pyright", "lua-language-server", "yaml-language-server" }
r.refresh(function()
  for _, name in ipairs(wanted) do
    local pkg = r.get_package(name)
    if not pkg:is_installed() then pkg:install() end
  end
end)
-- Wait until no install is in-flight (success or platform-unsupported both
-- end the install attempt), with a 5-minute cap for stuck networks.
vim.wait(300000, function()
  for _, n in ipairs(wanted) do
    if r.get_package(n):is_installing() then return false end
  end
  return true
end, 1000)
for _, n in ipairs(wanted) do
  print(string.format("  %s: %s", n, r.is_installed(n) and "installed" or "MISSING"))
end
LUA
nvim --headless "+luafile $prewarm_lua" +qa 2>&1 | grep -E "installed|MISSING" || true
rm -f "$prewarm_lua"

# ---- Copilot CLI + host/shared mount wiring -------------------------------
#
# Triggered only when the container was launched via the `dc` wrapper (or an
# equivalent setup) that bind-mounts the host Copilot dir at
# ~/.copilot-host. See dc/README.md for the full sharing model.
#
# Steps:
#   1. Install Copilot CLI globally via npm (idempotent: skip if present).
#   2. Symlink read-only host files into ~/.copilot/ (auth, settings,
#      skills, cross-session history DB).
#   3. Symlink writable shared files/dirs into ~/.copilot/ (session state,
#      command history, permissions, logs). Each devcontainer reads/writes
#      the same store on the host.
#   4. Stub ~/.copilot/mcp.json if missing — placeholder for user to fill.
#
# When ~/.copilot-host is not mounted, this whole section is a no-op.

bold "Copilot CLI (devcontainer wiring)"

if [ ! -d "$HOME/.copilot-host" ]; then
  log "no ~/.copilot-host mount → skipping Copilot setup"
  log "(launch via the host's 'dc up' to enable; see dc/README.md)"
else
  log "found ~/.copilot-host → wiring up Copilot"

  # Step 1: install Copilot CLI. The CLI is published as @github/copilot.
  if command -v copilot >/dev/null 2>&1; then
    log "✓ copilot already installed: $(command -v copilot)"
  else
    log "installing @github/copilot via npm"
    if $SUDO npm install -g @github/copilot >/dev/null 2>&1; then
      log "✓ copilot installed"
    else
      log "WARN: npm install -g @github/copilot failed; install manually inside the container"
    fi
  fi

  mkdir -p "$HOME/.copilot"

  # Step 2: read-only links from host. If a real file is in place from a
  # prior copilot launch, replace it with the symlink so host wins.
  for name in config.json settings.json skills session-store.db; do
    src="$HOME/.copilot-host/$name"
    dst="$HOME/.copilot/$name"
    if [ ! -e "$src" ]; then
      log "  skip $name (not present on host)"
      continue
    fi
    # Remove existing non-symlink so ln -sfn doesn't get confused on dirs.
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      rm -rf "$dst"
    fi
    ln -sfn "$src" "$dst"
    log "  ro-link: ~/.copilot/$name -> ~/.copilot-host/$name"
  done

  # Step 3: writable shared links. Ensure each target exists on the shared
  # side so the symlink is immediately usable.
  shared="$HOME/.copilot-shared"
  if [ ! -d "$shared" ]; then
    log "WARN: ~/.copilot-shared not mounted; per-container Copilot state will be ephemeral"
  else
    # Dirs that should always exist on the shared side.
    for d in session-state logs; do
      mkdir -p "$shared/$d"
    done
    # Files that may not exist yet — touch creates them empty so the
    # symlink target is valid.
    for f in command-history-state.json permissions-config.json; do
      [ -e "$shared/$f" ] || : > "$shared/$f"
    done
    # Now wire up the symlinks.
    for name in session-state logs command-history-state.json permissions-config.json; do
      dst="$HOME/.copilot/$name"
      src="$shared/$name"
      if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        rm -rf "$dst"
      fi
      ln -sfn "$src" "$dst"
      log "  rw-link: ~/.copilot/$name -> ~/.copilot-shared/$name"
    done
  fi

  # Step 4: MCP config stub. Plain JSON (no comments) so Copilot can parse
  # it as-is once the user fills in actual servers.
  mcp="$HOME/.copilot/mcp.json"
  if [ -e "$mcp" ] || [ -L "$mcp" ]; then
    log "✓ mcp.json already present"
  else
    cat > "$mcp" <<'JSON'
{
  "mcpServers": {}
}
JSON
    log "✓ stubbed empty mcp.json (fill in servers as needed; /obsidian is the vault mount)"
  fi
fi

bold "install.sh complete"
if [ "$moved" = 1 ]; then
  backup_msg="$backup"
else
  backup_msg="(none)"
fi
cat <<EOF
  Dotfiles installed for: $ID $VERSION_ID
  Skipped packages:       $STOW_SKIP
  Backup of pre-existing: $backup_msg

  Open a fresh shell (zsh recommended) or 'exec zsh' to load the new config.
EOF
