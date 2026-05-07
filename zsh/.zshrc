# Homebrew environment
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load plugins via Antidote
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh
antidote load

# zsh-autosuggestions highlight color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"

# Starship prompt
eval "$(starship init zsh)"

# zoxide: smarter directory jumping (replaces cd)
eval "$(zoxide init zsh --cmd cd)"

# atuin: enhanced shell history (takes over Ctrl+R and Up arrow)
eval "$(atuin init zsh)"

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
