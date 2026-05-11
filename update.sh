#!/bin/zsh

files=(ghostty zsh)
for file in $files; do
  echo "Updating: $file"
  stow --dotfiles --target=$HOME $file
done
