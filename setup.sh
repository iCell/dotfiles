#!/bin/zsh

# 1. Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Clone dotfiles if not cloned
if [[ ! -d ~/dotfiles ]]; then
  git clone --recursive https://github.com/iCell/dotfiles ~/dotfiles
fi

# 3. Install brew packages
brew bundle --file=~/dotfiles/Brewfile

# 4. Stow configs
cd ~/dotfiles
stow ghostty
stow zsh

echo "Done! Restart your terminal to apply changes."
