#!/bin/bash
# Bootstrap a fresh Mac with everything PREREQUISITES.md describes.
#
# READ PREREQUISITES.md BEFORE RUNNING THIS. If this script and the doc ever
# disagree, the doc is the source of truth — fix the script (and the
# Brewfile) to match.
#
# This script is safe to re-run: `brew bundle` and the conditional installs
# below are all idempotent.
#
# It does NOT:
#   - touch ~/.zshsecrets (you create that manually; see PREREQUISITES.md §5)
#   - run ./update.sh (run that yourself after reading the script's output)

set -euo pipefail

# ---- Helpers ---------------------------------------------------------------

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'USAGE'
Usage: ./bootstrap.sh [-y|--yes] [-h|--help]

  -y, --yes    Skip the interactive confirmation prompt.
  -h, --help   Show this help.
USAGE
}

assume_yes=0
while (( $# > 0 )); do
  case "$1" in
    -y|--yes) assume_yes=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# ---- Banner ----------------------------------------------------------------

cat <<'EOF'

============================================================
  dotfiles bootstrap
============================================================

This script installs everything PREREQUISITES.md describes:
  - Homebrew (if missing)
  - zsh and python3 (only if not already on PATH — macOS ships both)
  - Everything in ./Brewfile (formulae, taps, casks, fonts)

It does NOT create ~/.zshsecrets or run ./update.sh —
do those steps manually after this finishes.

If anything below looks wrong, hit Ctrl-C now and check
PREREQUISITES.md.

EOF

if (( assume_yes )); then
  info "--yes given; skipping confirmation."
else
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "aborted."; exit 1 ;;
  esac
fi

# ---- 1. Homebrew -----------------------------------------------------------

bold "1. Homebrew"

if have brew; then
  info "✓ brew already installed at: $(command -v brew)"
else
  info "installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Load brew into PATH for the rest of this script — eval the shellenv from
  # whichever prefix the installer chose (Apple Silicon vs Intel).
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $brew_bin ]]; then
      eval "$($brew_bin shellenv)"
      break
    fi
  done
fi

# ---- 2. System-shipped tools, install only if missing ----------------------
#
# zsh and python3 ship with modern macOS. Installing them via brew would
# shadow the system binaries (Homebrew's bin dir precedes /usr/bin in PATH),
# so we only fall back to brew when the system copy is genuinely absent.

bold "2. System-shipped tools"
if have zsh; then
  info "✓ zsh already present at: $(command -v zsh)"
else
  info "installing zsh…"
  brew install zsh
fi
if have python3; then
  info "✓ python3 already present at: $(command -v python3)"
else
  info "installing python3…"
  brew install python3
fi

# ---- 3. Brewfile -----------------------------------------------------------

bold "3. Brewfile (brew bundle)"
brew bundle --file="$script_dir/Brewfile"

# ---- 4. Done ---------------------------------------------------------------

cat <<'EOF'

============================================================
  bootstrap complete
============================================================

Next steps (manual):

  1. (Optional) Create ~/.zshsecrets if you have machine-local env vars
     you don't want to commit. See PREREQUISITES.md §5.

  2. Run ./update.sh to stow all config files into $HOME.

  3. Make Ghostty your default terminal (optional but recommended).

  4. Restart your shell. First launch of nvim / tmux / zsh will
     auto-clone plugins (Zinit, lazy.nvim, tpack-managed tmux plugins).

EOF
