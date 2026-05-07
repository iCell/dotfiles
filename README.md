# Dotfiles

My personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

- **Ghostty** — Terminal emulator config (Catppuccin theme, JetBrains Mono font, transparency, etc.)
- **Zsh** — Shell config with plugins managed by [antidote](https://github.com/mattmc3/antidote):
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-shift-select](https://github.com/jirutka/zsh-shift-select)
  - Custom Shift+Cmd+Arrow key bindings for line selection

## Quick Setup

One command to set up everything on a fresh Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/iCell/dotfiles/main/setup.sh | zsh
```

Or manually:

```sh
git clone https://github.com/iCell/dotfiles ~/dotfiles
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
    └── .zsh_plugins.txt   # antidote plugin list
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

To add a new zsh plugin, edit `zsh/.zsh_plugins.txt` and reload:

```sh
source ~/.zshrc
```
