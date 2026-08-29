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
# Atuin
#

if (( $+commands[atuin] )); then
    if [[ -z "${ZSH_SKIP_ATUIN_PTY_PROXY:-}" ]]; then
        eval "$(
            atuin pty-proxy init zsh |
                sed 's|--shell "${_atuin_pty_proxy_zsh#-}"|--shell "$(command -v zsh)"|'
        )"
    fi

    export ATUIN_NOBIND=true
    eval "$(atuin init zsh --disable-ai)"
    unset ATUIN_NOBIND

    ZSH_AUTOSUGGEST_STRATEGY=(history)
fi

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
# Functions
#

c() {
    emulate -L zsh

    if (( $# != 1 )) || [[ "$1" != <-> ]] || (( $1 < 1 || $1 > 128 )); then
        print -u2 'usage: c <1-128>'
        return 2
    fi

    if (( ! $+commands[zsh-copy-history] )); then
        print -u2 'c: zsh-copy-history is not installed'
        return 127
    fi

    local transcript
    transcript="$(zsh-copy-history "$1")" || return

    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-copy] )); then
        print -rn -- "$transcript" | wl-copy || {
            print -u2 'c: wl-copy failed'
            return 1
        }
    elif [[ -n "${DISPLAY:-}" ]] && (( $+commands[xclip] )); then
        print -rn -- "$transcript" | xclip -selection clipboard || {
            print -u2 'c: xclip failed'
            return 1
        }
    else
        print -u2 'c: no usable clipboard utility was found'
        return 127
    fi

    print -r -- "Copied $1 command(s) and output."
}

s() {
    emulate -L zsh

    local query="$*"
    if [[ -z "$query" ]]; then
        print -u2 'usage: s <search text>'
        return 2
    fi

    local starship_mauve=$'\e[38;2;203;166;247m'
    local starship_pink_sgr='38;2;245;194;231'
    local reset=$'\e[0m'
    local results

    results="$(
        fc -l -r 1 "$((HISTCMD - 1))" 2>/dev/null |
            command env GREP_COLORS="ms=$starship_pink_sgr" grep --color=always -iF -- "$query"
    )" || {
        print -r -- "No history matches for: $query"
        return 1
    }

    print -r -- "$results" |
        command sed -E "s/^([[:space:]]*[0-9]+)/${starship_mauve}\\1${reset}/"
}

#
# Aliases
#

alias u='sudo apt update;sudo apt upgrade;zsh-update-tools'
alias i='weechat'

#
# Keybinds
#

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
