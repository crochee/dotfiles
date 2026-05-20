# PATH configuration for bash

prepend-path() {
  [ -d "$1" ] && PATH="$1:$PATH"
}

prepend-path "$HOME/.local/share/nvim/mason/bin"

# set PATH so it includes user's private bin if it exists
prepend-path "$HOME/.local/bin"

prepend-path "$DOTFILES_DIR/bin"
