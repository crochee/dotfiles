if type kubectl >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(kubectl completion bash)
fi
if type zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
    alias cd="z"
fi
if type mcfly >/dev/null 2>&1; then
    eval "$(mcfly init bash)"
fi

if type uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

# if [ ! -d "$HOME/.venv" ] && type uv >/dev/null 2>&1; then
#     uv venv "$HOME/.venv"
# else
#     #shellcheck disable=SC1090
#     source "$HOME/.venv/bin/activate"
# fi
