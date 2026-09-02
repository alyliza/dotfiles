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
    eval "$(zoxide init zsh --cmd j)"
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

    local count="${1-1}"
    local skip="${2-0}"
    local invalid=0
    case "$count" in
        ''|*[!0-9]*) invalid=1 ;;
    esac
    case "$skip" in
        ''|*[!0-9]*) invalid=1 ;;
    esac
    if (( $# > 2 || invalid )); then
        print -u2 'usage: c [1-128] [0-128 commands to skip]'
        return 2
    fi
    if (( count < 1 || count > 128 || skip < 0 || skip > 128 )); then
        print -u2 'usage: c [1-128] [0-128 commands to skip]'
        return 2
    fi

    if (( ! $+commands[zsh-copy-history] )); then
        print -u2 'c: zsh-copy-history is not installed'
        return 127
    fi

    local transcript
    transcript="$(zsh-copy-history "$count" "$skip")" || return

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

    print -r -- "Copied $count command(s) and output."
}

_open_atuin_search() {
    if (( ! $+commands[atuin] )); then
        print -u2 'atuin is not installed'
        return 127
    fi
    ATUIN_SHELL=zsh atuin search --interactive
}

s() {
    emulate -L zsh

    local query="$*"
    if [[ -z "$query" ]]; then
        _open_atuin_search
        return
    fi

    local results

    results="$(
        fc -l -r 1 "$((HISTCMD - 1))" 2>/dev/null |
            command grep -iF -- "$query"
    )" || {
        print -r -- "No history matches for: $query"
        return 1
    }

    print -r -- "$results"
}

si() {
    emulate -L zsh

    local query="$*"
    if [[ -z "$query" ]]; then
        _open_atuin_search
        return
    fi
    if (( ! $+commands[zsh-copy-history] )); then
        print -u2 'si: zsh-copy-history is not installed'
        return 127
    fi

    zsh-copy-history --search "$query"
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
