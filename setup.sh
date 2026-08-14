#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
STOW_TARGET="${DOTFILES_DIR:h}"
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
load_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif command -v brew &>/dev/null; then
    eval "$(brew shellenv)"
  else
    return 1
  fi
}

if ! load_brew_shellenv; then
  brew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # When this script is piped into zsh (the README one-liner) stdin is not a TTY.
  # Homebrew then switches to non-interactive mode, probes sudo with `sudo -n`,
  # and aborts with "Need sudo access on macOS" because it cannot prompt for a
  # password. Hand it the controlling terminal so it stays interactive.
  if [[ -t 0 ]]; then
    /bin/bash -c "$brew_installer"
  elif [[ -r /dev/tty ]]; then
    /bin/bash -c "$brew_installer" < /dev/tty
  else
    echo "No terminal available to install Homebrew." >&2
    echo "Install Homebrew first, then re-run $SCRIPT_NAME." >&2
    exit 1
  fi
  load_brew_shellenv
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

BACKUP_SUFFIX=".pre-stow-$(date +%Y%m%d%H%M%S)"

# stow aborts an entire package on its first conflict, so a Mac that already has
# a real ~/.zshrc (or ~/.config/ghostty/config) would stop the script here. Move
# anything that is in the way — and not already our own link — aside first.
stow_pkg() {
  local pkg="$1" rel target
  local -a files
  files=("${(@f)$(cd "$pkg" && find . -type f ! -name .stow-local-ignore | sed 's|^\./||')}")
  for rel in $files; do
    [[ -n "$rel" ]] || continue
    target="$STOW_TARGET/$rel"
    [[ -e "$target" || -L "$target" ]] || continue
    [[ "${target:A}" == "${DOTFILES_DIR:A}/$pkg/$rel" ]] && continue
    echo "Backing up $target -> $target$BACKUP_SUFFIX"
    mv "$target" "$target$BACKUP_SUFFIX"
  done
  # --no-folding links leaf files only, never whole directories. Without it stow
  # would collapse a missing ~/.config into a single link into this repo, and then
  # everything that writes to ~/.config would be writing into the dotfiles repo.
  # --restow unfolds any such link left over from an earlier run.
  stow --target="$STOW_TARGET" --no-folding --restow "$pkg"
}

stow_pkg zsh
stow_pkg herdr

case "$PROFILE" in
  personal)
    stow_pkg ghostty
    ;;
  work)
    if [[ -d "$DOTFILES_DIR/iterm2" ]]; then
      stow_pkg iterm2
    fi
    ;;
esac

echo "Done! Restart your terminal to apply the $PROFILE profile."
