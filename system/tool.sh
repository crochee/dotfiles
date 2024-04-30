if type kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
fi
if type zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi
