# Dotfiles

My personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

- **Zsh** — Shared shell config with plugins managed by [antidote](https://github.com/mattmc3/antidote):
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
  - [zsh-shift-select](https://github.com/jirutka/zsh-shift-select)
  - Custom Shift+Cmd+Arrow key bindings for line selection
  - Per-machine additions in `~/.config/zsh/local.zsh` (see [Machine-local shell config](#machine-local-shell-config))
- **herdr** — Terminal workspace manager for AI coding agents. Only `config.toml` is synced; the logs, sockets and session state herdr writes alongside it stay machine-local (`setup.sh` stows with `--no-folding`, so `~/.config/herdr` is a real directory rather than a link into this repo).
- **Ghostty** — Personal terminal emulator config (Catppuccin theme, JetBrains Mono font, transparency, etc.)
- **iTerm2** — Work terminal profile support. iTerm2 itself is installed through company Self Service and is not managed by Homebrew.

## Quick Setup

> Requires an Apple Silicon Mac — Intel is not supported (Homebrew is assumed
> at `/opt/homebrew` throughout; `setup.sh` refuses to run on Intel).

Personal Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/iCell/dotfiles/main/setup.sh | zsh -s -- personal
```

Work Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/iCell/dotfiles/main/setup.sh | zsh -s -- work
```

Or manually:

```sh
git clone https://github.com/iCell/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh personal
# or, for a work Mac
./setup.sh work
```

### Profile confirmation

Run without an argument and `setup.sh` asks which profile to install before it
touches anything, so forgetting `work` on a work Mac cannot quietly install the
personal profile:

```
Which profile? [p]ersonal / [w]ork / [q]uit:
```

There is no default on an empty answer — it re-asks. If no terminal is available
to answer on, the script aborts rather than guessing; set `NONINTERACTIVE=1` to
accept the `personal` default instead.

Note that `NONINTERACTIVE=1` is also the Homebrew installer's own control
variable: on a Mac without Homebrew the installer inherits it and cannot prompt
for your password, so unattended runs need sudo pre-authorized (`sudo -v`
first) or Homebrew already installed.

## Machine-local shell config

There is one `zsh/.zshrc` here and it holds only what belongs on *every* machine.
Anything a single Mac needs — work-only aliases and `PATH` entries, credentials,
internal hostnames — goes in `~/.config/zsh/local.zsh`, which `~/.zshrc` sources
last so it can override anything above it.

That file is not in this repo and is never pushed anywhere, so work setup simply
does not exist on the personal Mac (and this repo is public — company-internal
details should not be committed to it in the first place). `setup.sh` creates an
empty one on a fresh machine and leaves an existing one untouched.

```sh
$EDITOR ~/.config/zsh/local.zsh
source ~/.zshrc                    # reload
```

A `PATH` entry only this machine needs goes in there as a `$path` prepend —
`.zshrc` sets `typeset -U path`, so re-sourcing it will not stack duplicates:

```zsh
path=("$HOME/bin" /opt/company/toolchain/bin $path)   # first wins
export SOME_TOKEN=...
```

`local.zsh` is loaded at the very end of `.zshrc`, so entries added here sit
ahead of Homebrew, rustup and mise. Note this is `.zshrc`, i.e. interactive
shells only — a `PATH` that GUI apps or `ssh host cmd` also need belongs in
`~/.zshenv` instead.

The trade-off is that local config is not backed up by this repo. If a work Mac
accumulates enough of it to be worth versioning, keep it in a private repo and
have `local.zsh` be a symlink into that checkout.

## Structure

```
~/dotfiles/
├── Brewfile.common   # Homebrew packages shared by all machines
├── Brewfile.personal # Personal Mac packages
├── Brewfile.work     # Work Mac packages; does not install iTerm2
├── setup.sh          # Profile-aware setup script
├── README.md
├── .gitignore        # safety net for herdr runtime files (logs, sockets, state)
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── herdr/
│   └── .config/
│       └── herdr/
│           └── config.toml
├── iterm2/           # Optional iTerm2 stow package for work machines
└── zsh/              # Shared shell config; per-machine bits live in
    ├── .zshrc        # ~/.config/zsh/local.zsh, outside this repo
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
