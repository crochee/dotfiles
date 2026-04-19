# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Set DOTFILES_DIR
export DOTFILES_DIR="$HOME/.dotfiles"

# set workspace
mkdir -p "$HOME/workspace"
mkdir -p "$HOME/.local/bin"
export WORKSPACE=$HOME/workspace

# Source environment variables
if [ -f "$DOTFILES_DIR/system/env.sh" ]; then
    source "$DOTFILES_DIR/system/env.sh"
fi

# Remove duplicates (preserving prepended items)
# Source: http://unix.stackexchange.com/a/40755

PATH=$(echo -n "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')

export PATH

# Source aliases
if [ -f "$DOTFILES_DIR/system/alias.sh" ]; then
    source "$DOTFILES_DIR/system/alias.sh"
fi

# Bash specific configuration

# Enable colored output
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Enable history
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:pwd:exit:history"

# Enable completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

# Source all .sh files in system directory
for DOTFILE in "$DOTFILES_DIR/system"/{git.sh,path.sh,tools.sh}; do
    # shellcheck disable=SC1090
    source "$DOTFILE" 2>/dev/null
done

# Source bash plugins
# fzf
if [ -d "$DOTFILES_DIR/plugins/fzf" ]; then
    if [ -f "$DOTFILES_DIR/plugins/fzf/shell/completion.bash" ]; then
        source "$DOTFILES_DIR/plugins/fzf/shell/completion.bash"
    fi
    if [ -f "$DOTFILES_DIR/plugins/fzf/shell/key-bindings.bash" ]; then
        source "$DOTFILES_DIR/plugins/fzf/shell/key-bindings.bash"
    fi
fi
