# Prepend new items to path (if directory exists)

prepend-path() {
  [ -d "$1" ] && PATH="$1:$PATH"
}

prepend-path "$GOROOT/bin"
prepend-path "$GOPATH/bin"
prepend-path "$HOME/.local/share/nvim/mason/bin"

# set PATH so it includes user's private bin if it exists
prepend-path "$HOME/.local/bin"

prepend-path "$HOME/.local/bin/nvim-linux64/bin"
