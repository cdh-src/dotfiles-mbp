#!/bin/bash
# Drift detector for the Nord palette duplicated across tmux/starship/lualine.
#
# We deliberately keep these hex codes inlined in multiple files rather than
# introducing a templating step (see CLAUDE.md). This script verifies they
# haven't drifted: every consumer file must use *only* hex codes from
# CANONICAL, and every code in CANONICAL must appear in *some* consumer
# (so retiring a color is also a deliberate, drift-tested operation).
#
# Run via ./scripts/lint.sh, or directly:  ./scripts/lint-palette.sh

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

# ---- Canonical Nord palette (single source of truth) -----------------------
# Lowercase hex, no '#'. If you change this list, update every consumer.
CANONICAL=(
  2e3440  # nord0  base bg
  4c566a  # nord3  dim fg
  d8dee9  # nord4  fg
  8fbcbb  # nord7  frost teal
  88c0d0  # nord8  frost light blue (accent)
  81a1c1  # nord9  frost dark blue
  bf616a  # nord11 red
  d08770  # nord12 orange
  ebcb8b  # nord13 yellow
  a3be8c  # nord14 green
  b48ead  # nord15 purple
)

CONSUMERS=(
  tmux/dot-tmux.status.conf
  tmux/dot-config/tmux/git_branch.sh
  starship/dot-config/starship.toml
  nvim/dot-config/nvim/lua/plugins/lualine.lua
)

allowed=$(printf '%s\n' "${CANONICAL[@]}" | awk '{print $1}' | sort -u)

fail=0
for f in "${CONSUMERS[@]}"; do
  if [[ ! -f $f ]]; then
    echo "lint-palette: missing consumer file: $f" >&2
    fail=1
    continue
  fi
  used=$(grep -hoE '#[0-9a-fA-F]{6}' "$f" 2>/dev/null | tr -d '#' | tr 'A-F' 'a-f' | sort -u || true)
  unknown=$(comm -23 <(echo "$used") <(echo "$allowed") | sed '/^$/d' || true)
  if [[ -n $unknown ]]; then
    echo "lint-palette: $f uses non-Nord hex codes:" >&2
    # shellcheck disable=SC2001
    echo "$unknown" | sed 's/^/  #/' >&2
    fail=1
  fi
done

all_used=$(grep -hoE '#[0-9a-fA-F]{6}' "${CONSUMERS[@]}" 2>/dev/null | tr -d '#' | tr 'A-F' 'a-f' | sort -u || true)
unused=$(comm -23 <(echo "$allowed") <(echo "$all_used") | sed '/^$/d' || true)
if [[ -n $unused ]]; then
  echo "lint-palette: canonical colors with no consumer (retire from CANONICAL?):" >&2
  # shellcheck disable=SC2001
  echo "$unused" | sed 's/^/  #/' >&2
  fail=1
fi

if (( fail == 0 )); then
  echo "lint-palette: ok (${#CANONICAL[@]} canonical colors, ${#CONSUMERS[@]} consumers)"
fi
exit $fail
