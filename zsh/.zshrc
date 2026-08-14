# Homebrew environment (Apple Silicon only — Intel is not supported)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keep $path and $fpath free of duplicates. Without this, every `source
# ~/.zshrc` in a live shell appends another copy of each entry added below and
# in ~/.config/zsh/local.zsh.
typeset -U path fpath

# Completions: pick up brew-installed functions, then initialize the system
# (compinit must run before plugins that call compdef)
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit

# Load plugins via Antidote
source $HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh
antidote load

# zsh-autosuggestions highlight color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"

# Starship prompt
eval "$(starship init zsh)"

# zoxide: smarter directory jumping (replaces cd)
eval "$(zoxide init zsh --cmd cd)"

# atuin: enhanced shell history (takes over Ctrl+R and Up arrow)
eval "$(atuin init zsh)"

eval "$(mise activate zsh)"

# Shift-select: extend selection to start/end of line
shift-select-line-left() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle beginning-of-line
}
shift-select-line-right() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle end-of-line
}
zle -N shift-select-line-left
zle -N shift-select-line-right
bindkey $'\e[1;10D' shift-select-line-left
bindkey $'\e[1;10C' shift-select-line-right

# rustup shims (rustc, cargo, ...)
export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH"

# Machine-local config, loaded last so it can override anything above. This
# file is not part of the dotfiles repo and never leaves the machine it is on:
# work-only aliases and PATH entries, credentials, internal hostnames. Missing
# file simply means there is nothing to load. setup.sh seeds an empty one.
# Written as an `if` rather than `[[ ... ]] && source`: as the last line of
# .zshrc the latter would leave $? at 1 whenever the file is absent, and
# starship would paint the very first prompt red.
if [[ -r "$HOME/.config/zsh/local.zsh" ]]; then
  source "$HOME/.config/zsh/local.zsh"
fi
