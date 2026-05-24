#!/bin/bash
# Repo lint: syntax-check shell scripts and run palette drift detector.
# Adds: shellcheck on bash scripts (bootstrap.sh) -- skipped if not installed.
#
# Run from anywhere:  ./scripts/lint.sh

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

fail=0
ran=0

step() { printf '\n== %s ==\n' "$*"; }

# ---- zsh -n on every zsh script -------------------------------------------
step "zsh -n (syntax check)"
zsh_files=(
  update.sh
  tmux/dot-config/tmux/git_branch.sh
  tmux/dot-config/tmux/battery.sh
  zsh/dot-zshenv
  zsh/dot-zshrc
  zsh/dot-zprofile
  zsh/dot-config/zsh/zinit-bootstrap.zsh
)
for f in "${zsh_files[@]}"; do
  ran=$((ran + 1))
  if [[ ! -f $f ]]; then
    echo "  missing: $f"
    fail=1
    continue
  fi
  if zsh -n "$f"; then
    echo "  ok: $f"
  else
    echo "  FAIL: $f"
    fail=1
  fi
done

# ---- shellcheck on bash scripts -------------------------------------------
step "shellcheck (bash)"
bash_files=(
  bootstrap.sh
  scripts/lint.sh
  scripts/lint-palette.sh
)
if command -v shellcheck >/dev/null 2>&1; then
  for f in "${bash_files[@]}"; do
    ran=$((ran + 1))
    if [[ ! -f $f ]]; then
      echo "  missing: $f"
      fail=1
      continue
    fi
    if shellcheck "$f"; then
      echo "  ok: $f"
    else
      echo "  FAIL: $f"
      fail=1
    fi
  done
else
  echo "  shellcheck not installed; skipping (brew install shellcheck)"
fi

# ---- shellcheck on POSIX sh scripts ---------------------------------------
step "shellcheck (posix sh)"
posix_files=(
  install.sh
)
if command -v shellcheck >/dev/null 2>&1; then
  for f in "${posix_files[@]}"; do
    ran=$((ran + 1))
    if [[ ! -f $f ]]; then
      echo "  missing: $f"
      fail=1
      continue
    fi
    if shellcheck -s sh "$f"; then
      echo "  ok: $f"
    else
      echo "  FAIL: $f"
      fail=1
    fi
  done
else
  echo "  shellcheck not installed; skipping (brew install shellcheck)"
fi

# ---- palette drift --------------------------------------------------------
step "palette drift"
ran=$((ran + 1))
if ! ./scripts/lint-palette.sh; then
  fail=1
fi

# ---- summary --------------------------------------------------------------
echo
if (( fail == 0 )); then
  echo "lint: ok ($ran checks)"
else
  echo "lint: FAILED"
fi
exit $fail
