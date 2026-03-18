source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source ~/.zsh/zsh-shift-select/zsh-shift-select.plugin.zsh

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
