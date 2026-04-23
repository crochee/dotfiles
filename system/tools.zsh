# Tools configurations for zsh

# fzf configuration
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    else
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.*"'
    fi
fi

if command -v kubectl &> /dev/null; then
    # shellcheck disable=SC1090
    source <(kubectl completion zsh)
fi

if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion zsh)"
fi

# Starship configuration
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# zoxide configuration
if command -v zoxide &> /dev/null; then
    export _ZO_ECHO=1
    export _ZO_MAXAGE=10000
    export _ZO_DOCTOR=0
    eval "$(zoxide init zsh --cmd cd)"
fi

if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi
