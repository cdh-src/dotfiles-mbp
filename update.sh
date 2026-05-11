#!/bin/zsh

mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

files=(ghostty zsh nvim)
for file in $files; do
  echo "Updating: $file"
  stow --dotfiles --target=$HOME $file
done
