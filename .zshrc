#
# ~/.zshrc
#

#
# PATH
#

typeset -U path PATH

path=(
    "$HOME/.local/bin"
    "$HOME/.local/share/fnm"
    "$HOME/go/bin"
    "/usr/local/go/bin"
    $path
)

#
# Completions
#

if [[ -d "$HOME/.local/share/zsh/site-functions" ]]; then
    fpath=(
        "$HOME/.local/share/zsh/site-functions"
        $fpath
    )
fi

#
# Plugins Loaded First
#

if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

#
# Plugins
#

ZSH_DISABLE_COMPFIX=false
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80
ZSH_AUTOSUGGEST_HISTORY_IGNORE='?(#c80,)'

if [[ -r "$HOME/.antidote/antidote.zsh" ]]; then
    source "$HOME/.antidote/antidote.zsh"
    antidote load "$HOME/.zsh_plugins"
fi

if (( $+commands[pay-respects] )); then
    eval "$(pay-respects zsh --alias)"
fi

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

#
# Aliases
#

alias u='sudo apt update;sudo apt upgrade;update-zsh-tools'
alias i='weechat'

#
# Keybinds
#

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
