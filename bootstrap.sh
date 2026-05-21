#!/bin/bash
# Bootstrap a fresh Mac with everything PREREQUISITES.md describes.
#
# READ PREREQUISITES.md BEFORE RUNNING THIS. The file lists every install
# this script will perform and why. If those two files ever disagree, the
# doc is the source of truth — fix the script to match.
#
# This script is idempotent: re-running it on an already-set-up machine
# is a no-op (everything is gated on a "is it already present?" check).
#
# It does NOT:
#   - touch ~/.zshsecrets (you create that manually; see PREREQUISITES.md §5)
#   - run ./update.sh (run that yourself after reading the script's output)

set -euo pipefail

# ---- Helpers ---------------------------------------------------------------

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
warn()  { printf '\033[33m  warning: %s\033[0m\n' "$*" >&2; }
have()  { command -v "$1" >/dev/null 2>&1; }

# brew_install <formula>          installs if not already present
brew_install() {
  local formula=$1
  if brew list --formula "$formula" >/dev/null 2>&1; then
    info "✓ $formula already installed"
  else
    info "installing $formula…"
    brew install "$formula"
  fi
}

# brew_cask_install <cask>        installs if not already present
brew_cask_install() {
  local cask=$1
  if brew list --cask "$cask" >/dev/null 2>&1; then
    info "✓ $cask already installed"
  else
    info "installing cask $cask…"
    brew install --cask "$cask"
  fi
}

# brew_tap_install <tap> <formula>
brew_tap_install() {
  local tap=$1 formula=$2
  if brew list --formula "$formula" >/dev/null 2>&1; then
    info "✓ $formula already installed"
  else
    info "tapping $tap and installing $formula…"
    brew tap "$tap" >/dev/null 2>&1 || true
    brew install "$formula"
  fi
}

# ---- Banner ----------------------------------------------------------------

cat <<'EOF'

============================================================
  dotfiles bootstrap
============================================================

This script installs everything PREREQUISITES.md describes:
  - Homebrew (if missing)
  - Hard requirements: git, stow, zsh
  - Config tools:     tmux, tpack, starship, neovim, ghostty,
                      lsd, zoxide, python3, uv
  - LiteLLM:          via `uv tool install --python 3.13 'litellm[proxy]'`
                      (Python pin matters; newer Pythons have broken proxy deps)
  - Font:             0xProto Nerd Font

It does NOT create ~/.zshsecrets or run ./update.sh —
do those steps manually after this finishes.

If anything below looks wrong, hit Ctrl-C now and check
PREREQUISITES.md.

EOF

read -r -p "Continue? [y/N] " reply
case "$reply" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "aborted."; exit 1 ;;
esac

# ---- 1. Homebrew -----------------------------------------------------------

bold "1. Homebrew"

if have brew; then
  info "✓ brew already installed at: $(command -v brew)"
else
  info "installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Load brew into PATH for the rest of this script — eval the shellenv from
  # whichever prefix the installer chose.
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $brew_bin ]]; then
      eval "$($brew_bin shellenv)"
      break
    fi
  done
fi

# ---- 2. Hard requirements --------------------------------------------------

bold "2. Hard requirements"
brew_install git
brew_install stow
# zsh ships with modern macOS; only install if missing.
if have zsh; then
  info "✓ zsh already present at: $(command -v zsh)"
else
  brew_install zsh
fi

# ---- 3. Config tools -------------------------------------------------------

bold "3. Config tools"
brew_install tmux
brew_tap_install tmuxpack/tpack tpack
brew_install starship
brew_install neovim
brew_cask_install ghostty
brew_install lsd
brew_install zoxide
brew_install python3
brew_install uv

# LiteLLM is a Python package installed via uv into an isolated venv.
# IMPORTANT: pin Python to 3.13 — some of LiteLLM's proxy dependencies have
# historically lagged on newer Python releases and produce import errors
# otherwise. The [proxy] extras (uvicorn, fastapi, etc.) are required for
# ai_proxy.sh to work.
bold "  LiteLLM (via uv, pinned to Python 3.13)"
if have litellm; then
  info "✓ litellm already installed at: $(command -v litellm)"
else
  info "installing litellm via uv tool install…"
  uv tool install --python 3.13 'litellm[proxy]'
fi

# ---- 4. Fonts --------------------------------------------------------------

bold "4. Fonts"
brew_cask_install font-0xproto-nerd-font

# ---- 5. Done ---------------------------------------------------------------

cat <<'EOF'

============================================================
  bootstrap complete
============================================================

Next steps (manual):

  1. Create ~/.zshsecrets and add:
       export ANTHROPIC_AUTH_TOKEN='paste-a-random-string-here'

  2. Run ./update.sh to stow all config files into $HOME.

  3. Make Ghostty your default terminal (optional but recommended).

  4. Restart your shell. First launch of nvim / tmux / zsh will
     auto-clone plugins (Zinit, lazy.nvim, tpack-managed tmux plugins).

EOF
