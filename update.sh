#!/bin/zsh

cd "${0:A:h}"

files=( *(N/) )
for file in $files; do
  echo "Updating: $file"
  stow --dotfiles --no-folding --target=$HOME $file
done
