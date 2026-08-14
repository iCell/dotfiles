#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DEFAULT_PROFILE="personal"
PROFILE="${1:-$DEFAULT_PROFILE}"
SCRIPT_NAME="${0:t}"

if [[ "$SCRIPT_NAME" == "zsh" || "$SCRIPT_NAME" == "-zsh" ]]; then
  SCRIPT_NAME="setup.sh"
fi

usage() {
  echo "Usage: $SCRIPT_NAME [personal|work] (default: $DEFAULT_PROFILE)"
}

case "$PROFILE" in
  personal|work) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

# 1. Install Homebrew if not installed
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 2. Clone dotfiles if not cloned
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone --recursive https://github.com/iCell/dotfiles "$DOTFILES_DIR"
fi

# 3. Install brew packages
brew bundle --file="$DOTFILES_DIR/Brewfile.common"
brew bundle --file="$DOTFILES_DIR/Brewfile.$PROFILE"

# 4. Stow configs
cd "$DOTFILES_DIR"
stow zsh

case "$PROFILE" in
  personal)
    stow ghostty
    ;;
  work)
    if [[ -d "$DOTFILES_DIR/iterm2" ]]; then
      stow iterm2
    fi
    ;;
esac

echo "Done! Restart your terminal to apply the $PROFILE profile."
