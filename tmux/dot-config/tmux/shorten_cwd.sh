#!/bin/zsh
# Shorten a path for the tmux status bar:
#   $HOME              -> ~
#   /Users/foo/bar/baz -> ~/b/baz  (parent dirs collapsed to first letter)
#
# Argument: an absolute path (typically #{pane_current_path}).

set -u
path="${1:-$PWD}"

# Replace $HOME with ~
case "$path" in
  "$HOME") print -- "~"; exit 0 ;;
  "$HOME"/*) path="~${path#$HOME}" ;;
esac

# Split on /, abbreviate all but the last component to its first char.
typeset -a parts
parts=("${(@s:/:)path}")
last=${#parts[@]}

out=""
for i in {1..$last}; do
  seg="${parts[$i]}"
  if (( i == last )) || [[ -z "$seg" ]]; then
    out+="$seg"
  else
    # Keep ~ as-is; otherwise take the first character (handle leading dot).
    if [[ "$seg" == "~" ]]; then
      out+="~"
    elif [[ "$seg" == .* ]]; then
      out+="${seg:0:2}"
    else
      out+="${seg:0:1}"
    fi
  fi
  (( i < last )) && out+="/"
done

print -- "$out"
