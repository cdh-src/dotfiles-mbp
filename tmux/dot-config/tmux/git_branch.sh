#!/bin/zsh
# Emit a tmux-formatted git status segment for the active pane's cwd:
#
#   main                               (clean)
#   main ↑2                            (2 commits ahead of upstream)
#   main ↑2 ↓1 ●3 ○5 …2 ⚔1 ⚑2      (everything at once)
#    abc1234                           (detached HEAD)
#
# Symbols: ↑ ahead, ↓ behind, ● staged, ○ unstaged, … untracked,
#          ⚔ conflicts, ⚑ stash entries. Zero-count categories are hidden.
#
# Outputs nothing when not inside a git repo, so the surrounding tmux
# conditional in status-left collapses the whole segment.
#
# Argument: path to inspect (typically `#{pane_current_path}`).

set -u
cd "${1:-$PWD}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ---- Palette (nord, mirrors dot-tmux.status.conf) --------------------------
C_BRANCH="#[fg=#a3be8c]"     # nord14 green
C_AHEAD="#[fg=#a3be8c]"      # green
C_BEHIND="#[fg=#bf616a]"     # nord11 red
C_STAGED="#[fg=#ebcb8b]"     # nord13 yellow
C_UNSTAGED="#[fg=#d08770]"   # nord12 orange
C_UNTRACKED="#[fg=#4c566a]"  # nord3 dim grey
C_CONFLICT="#[fg=#bf616a,bold]"
C_STASH="#[fg=#b48ead]"      # nord15 purple
C_BRACKET="#[fg=#4c566a]"    # dim grey
C_RESET="#[default]"

branch=""; oid=""
ahead=0; behind=0
staged=0; unstaged=0; untracked=0; conflicts=0; stash=0

# Single git call for everything except stash. porcelain=v2 gives a stable
# line-prefix format (1/2/u/? for file entries, # for headers).
while IFS= read -r line; do
  case "$line" in
    '# branch.head '*)
      branch=${line#'# branch.head '} ;;
    '# branch.oid '*)
      oid=${line#'# branch.oid '} ;;
    '# branch.ab '*)
      # Format: "# branch.ab +<ahead> -<behind>"
      ab=${line#'# branch.ab '}
      a=${ab%% *}; b=${ab#* }
      ahead=${a#+}; behind=${b#-}
      ;;
    '1 '*|'2 '*)
      # XY = positions 3-4. X = index (staged), Y = worktree (unstaged).
      # '.' means no change in that column.
      x=${line[3]}; y=${line[4]}
      [[ $x != '.' ]] && (( staged++ ))
      [[ $y != '.' ]] && (( unstaged++ ))
      ;;
    'u '*) (( conflicts++ )) ;;
    '? '*) (( untracked++ )) ;;
  esac
done < <(git status --porcelain=v2 --branch 2>/dev/null)

# Stash count is not in porcelain=v2; one extra cheap call.
stash=$(git stash list --no-decorate 2>/dev/null | grep -c .)

# ---- Branch / detached HEAD display ----------------------------------------
if [[ "$branch" == "(detached)" ]]; then
  branch_text="${oid:0:7}"
else
  branch_text="$branch"
fi
# `` is U+E0A0 nf-pl-branch.
# branch_display="${C_BRANCH}${branch_text}${C_RESET}"
branch_display="${C_BRANCH}${branch_text}${C_RESET}"

# ---- Status segments -------------------------------------------------------
typeset -a segments
(( ahead > 0 ))     && segments+=("${C_AHEAD}↑${ahead}")
(( behind > 0 ))    && segments+=("${C_BEHIND}↓${behind}")
(( staged > 0 ))    && segments+=("${C_STAGED}●${staged}")
(( unstaged > 0 ))  && segments+=("${C_UNSTAGED}○${unstaged}")
(( untracked > 0 )) && segments+=("${C_UNTRACKED}…${untracked}")
(( conflicts > 0 )) && segments+=("${C_CONFLICT}⚔${conflicts}")
(( stash > 0 ))     && segments+=("${C_STASH}⚑${stash}")

if (( ${#segments[@]} > 0 )); then
  inside="${(j: :)segments}"
  print -- "${branch_display} ${inside}${C_RESET}"
else
  print -- "${branch_display}"
fi
