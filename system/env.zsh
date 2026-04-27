# Environment variables for zsh

# Other environment variables
export COLORTERM="truecolor"

if [[ -z "$LANG" ]]; then
    export LANG=en_US.UTF-8
fi

source "$DOTFILES_DIR/system/.env"
