#!/bin/zsh
# Print the current git branch with a trailing "*" when the working tree is dirty.
# Prints nothing if not inside a git repo (so the tmux segment collapses).
#
# Argument: path to run the check in (typically #{pane_current_path}).

set -u
cd "${1:-$PWD}" 2>/dev/null || exit 0

# Bail quietly if not in a repo.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git rev-parse --short HEAD 2>/dev/null)"
[[ -z "$branch" ]] && exit 0

# `git status --porcelain` is empty when clean.
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  print -- "${branch}*"
else
  print -- "$branch"
fi
