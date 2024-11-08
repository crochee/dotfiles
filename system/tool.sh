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

if [ -d ~/.pyvenv ]; then
    #shellcheck disable=SC1090
    source ~/.pyvenv/bin/activate
else
    python3 -m venv ~/.pyvenv
fi
