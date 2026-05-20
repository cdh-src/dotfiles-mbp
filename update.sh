#!/bin/zsh
# Re-stow every package in this repo into $HOME. Idempotent.
#
# Each top-level directory is a stow package using the --dotfiles convention
# (dot-foo → ~/.foo). --no-folding keeps stow at the file level so multiple
# packages can contribute into the same target directory (e.g. ~/.config/).
#
# If you're new to this machine, read PREREQUISITES.md first and consider
# running ./bootstrap.sh to install the tools and fonts referenced by these
# configs.

set -u

cd "${0:A:h}"

if ! command -v stow >/dev/null 2>&1; then
  print -u2 "error: 'stow' is not installed."
  print -u2 "       See PREREQUISITES.md, or run ./bootstrap.sh to install it."
  exit 1
fi

files=( *(N/) )
fail=0
for file in $files; do
  echo "Updating: $file"
  if ! stow --dotfiles --no-folding --target=$HOME "$file"; then
    print -u2 "error: stow failed for package: $file"
    fail=1
  fi
done
exit $fail
