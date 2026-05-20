# Environment variables

# Enable colors
export CLICOLOR=1

if [[ -z "$LANG" ]]; then
    export LANG=C.UTF-8
fi

source "$DOTFILES_DIR/system/.env"
