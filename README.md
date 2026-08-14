# Dotfiles

My personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

- **Zsh** — Shared shell config with plugins managed by [antidote](https://github.com/mattmc3/antidote):
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-shift-select](https://github.com/jirutka/zsh-shift-select)
  - Custom Shift+Cmd+Arrow key bindings for line selection
- **Ghostty** — Personal terminal emulator config (Catppuccin theme, JetBrains Mono font, transparency, etc.)
- **iTerm2** — Work terminal profile support. iTerm2 itself is installed through company Self Service and is not managed by Homebrew.

## Quick Setup

Personal Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/iCell/dotfiles/main/setup.sh | zsh
```

Work Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/iCell/dotfiles/main/setup.sh | zsh -s -- work
```

Or manually:

```sh
git clone https://github.com/iCell/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh       # defaults to personal
# or, for a work Mac
./setup.sh work
```

## Structure

```
~/dotfiles/
├── Brewfile.common   # Homebrew packages shared by all machines
├── Brewfile.personal # Personal Mac packages
├── Brewfile.work     # Work Mac packages; does not install iTerm2
├── setup.sh          # Profile-aware setup script
├── README.md
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── iterm2/           # Optional iTerm2 stow package for work machines
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
brew bundle dump --file=/tmp/Brewfile --force
```

Then move the generated entries into `Brewfile.common`, `Brewfile.personal`, or `Brewfile.work`.

To add a new zsh plugin, edit `zsh/.zsh_plugins.txt` and reload:

```sh
source ~/.zshrc
```
