# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Resolve DOTFILES_DIR (assuming ~/.dotfiles on distros without readlink and/or $BASH_SOURCE/$0)
if [[ -n ${BASH_SOURCE[0]} && -x readlink ]]; then
    DOTFILES_DIR="${PWD}/$(dirname "$(readlink -n "${CURRENT_SCRIPT[0]}")")"
elif [ -d "$HOME/.dotfiles" ]; then
    DOTFILES_DIR="$HOME/.dotfiles"
else
    echo "Unable to find dotfiles, exiting."
    return
fi

export DOTFILES_DIR

# set workspace
mkdir -p "$HOME/workspace"
mkdir -p "$HOME/.local/bin"
export WORKSPACE=$HOME/workspace

# Make utilities available
PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)
for DOTFILE in "$DOTFILES_DIR/system"/{.alias,.env,*.sh,*.bash}; do
    # shellcheck disable=SC1090
    source "$DOTFILE"
done

# Wrap up

unset DOTFILE

# Remove duplicates (preserving prepended items)
# Source: http://unix.stackexchange.com/a/40755

PATH=$(echo -n "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')

export PATH
