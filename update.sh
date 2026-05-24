#!/bin/zsh
# Re-stow every package in this repo into $HOME. Idempotent.
#
# Each top-level directory is a stow package using the --dotfiles convention
# (dot-foo → ~/.foo). --no-folding keeps stow at the file level so multiple
# packages can contribute into the same target directory (e.g. ~/.config/).
# -R (restow) removes stale links from previous runs before re-creating them,
# so renamed/removed files don't leave dangling symlinks in $HOME.
#
# Package discovery: every top-level directory is treated as a stow package
# unless it appears in STOW_IGNORE below. Add non-package dirs (utility
# scripts, docs, etc.) to STOW_IGNORE — do NOT name them after a stowable
# target.
#
# To retire a package, run `stow -D <pkg>` BEFORE deleting it from the repo;
# stow can't unstow what no longer exists in the source tree.
#
# If you're new to this machine, read PREREQUISITES.md first and consider
# running ./bootstrap.sh to install the tools and fonts referenced by these
# configs.

setopt err_exit nounset pipe_fail

cd "${0:A:h}"

if ! command -v stow >/dev/null 2>&1; then
  print -u2 "error: 'stow' is not installed."
  print -u2 "       See PREREQUISITES.md, or run ./bootstrap.sh to install it."
  exit 1
fi

# Top-level directories that are NOT stow packages. Keep this short.
typeset -A STOW_IGNORE
STOW_IGNORE=(
  scripts 1   # repo-local utilities (lint.sh, lint-palette.sh, …)
)

# Caller-supplied additional skips (space-separated package names).
# install.sh uses this to skip macOS-only packages (ghostty, tmux) when
# stowing into a Linux dev container.
if [[ -n ${STOW_SKIP:-} ]]; then
  for p in ${(s: :)STOW_SKIP}; do
    STOW_IGNORE[$p]=1
  done
fi

fail=0
for pkg in *(N/); do
  if (( ${+STOW_IGNORE[$pkg]} )); then
    continue
  fi
  echo "Updating: $pkg"
  if ! stow -R --dotfiles --no-folding --target="$HOME" "$pkg"; then
    print -u2 "error: stow failed for package: $pkg"
    fail=1
  fi
done
exit $fail
