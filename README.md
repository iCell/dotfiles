# Dotfiles

My personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

- **Ghostty** — Terminal emulator config (Catppuccin theme, JetBrains Mono font, transparency, etc.)
- **Zsh** — Shell config with plugins:
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) (via Homebrew)
  - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) (via Homebrew)
  - [zsh-shift-select](https://github.com/jirutka/zsh-shift-select) (via Git submodule)
  - Custom Shift+Cmd+Arrow key bindings for line selection

## Quick Setup

One command to set up everything on a fresh Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/setup.sh | zsh
```

Or manually:

```sh
git clone --recursive https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Structure

```
~/dotfiles/
├── Brewfile          # Homebrew packages
├── setup.sh          # One-click setup script
├── README.md
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
└── zsh/
    ├── .zshrc
    └── .zsh/
        └── zsh-shift-select/  (submodule)
```

## Updating

After making changes to any config:

```sh
cd ~/dotfiles
git add .
git commit -m "update configs"
git push
```

After installing new Homebrew packages:

```sh
brew bundle dump --file=~/dotfiles/Brewfile --force
```
