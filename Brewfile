# Brewfile — declarative manifest for `brew bundle`.
#
# Anything brew-installable for this dotfiles repo lives here. The two
# exceptions are zsh and python3: both ship with modern macOS, and we don't
# want Homebrew versions to shadow the system ones in PATH. bootstrap.sh
# installs those conditionally only if `command -v` reports them missing.
#
# Sync rule (see PREREQUISITES.md): adding a new brew dep to the repo means
# adding a line here. From the repo root, `brew bundle check --file=./Brewfile`
# is the drift test.

tap "tmuxpack/tpack"

brew "git"
brew "stow"
brew "tmux"
brew "tpack"
brew "starship"
brew "neovim"
brew "lsd"
brew "zoxide"

cask "ghostty"
cask "font-0xproto-nerd-font"
