# If not running interactively, don't do anything
[[ -z $PS1 ]] && return

# Set DOTFILES_DIR
export DOTFILES_DIR="$HOME/.dotfiles"

# set workspace
mkdir -p "$HOME/workspace"
mkdir -p "$HOME/.local/bin"
export WORKSPACE=$HOME/workspace

# Source environment variables
if [ -f "$DOTFILES_DIR/system/env.zsh" ]; then
    source "$DOTFILES_DIR/system/env.zsh"
fi

PATH=$(echo -n "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')

export PATH

# Source aliases
if [ -f "$DOTFILES_DIR/system/alias.zsh" ]; then
    source "$DOTFILES_DIR/system/alias.zsh"
fi

# Zsh specific configuration

# Enable colored output
autoload -U colors && colors

# Enable history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Enable completion
autoload -U compinit
compinit

# Enable correction
setopt correct_all

# Enable globbing
setopt extended_glob

# Enable auto cd
setopt auto_cd

# Enable auto pushd
setopt auto_pushd

# Enable prompt substitution
setopt prompt_subst

# Source zsh specific dotfiles
for DOTFILE in "$DOTFILES_DIR/system"/{git.sh,path.sh,tools.zsh}; do
    # shellcheck disable=SC1090
    source "$DOTFILE" 2>/dev/null
done

# Source zsh plugins
# zsh-autosuggestions
if [ -f "$DOTFILES_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$DOTFILES_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting
if [ -f "$DOTFILES_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$DOTFILES_DIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Source zsh plugins
# fzf
if [ -d "$DOTFILES_DIR/plugins/fzf" ]; then
    if [ -f "$DOTFILES_DIR/plugins/fzf/shell/completion.zsh" ]; then
        source "$DOTFILES_DIR/plugins/fzf/shell/completion.zsh"
    fi
    if [ -f "$DOTFILES_DIR/plugins/fzf/shell/key-bindings.zsh" ]; then
        source "$DOTFILES_DIR/plugins/fzf/shell/key-bindings.zsh"
    fi
fi

# Source zsh plugins if any
if [ -d "$HOME/.oh-my-zsh" ]; then
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi