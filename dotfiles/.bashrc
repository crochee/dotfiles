# If not running interactively, don't do anything

[ -z "$PS1" ] && return

# Resolve DOTFILES_DIR (assuming ~/.dotfiles on distros without readlink and/or $BASH_SOURCE/$0)
CURRENT_SCRIPT=$BASH_SOURCE

if [[ -n $CURRENT_SCRIPT && -x readlink ]]; then
  SCRIPT_PATH=$(readlink -n $CURRENT_SCRIPT)
  DOTFILES_DIR="${PWD}/$(dirname $(dirname $SCRIPT_PATH))"
elif [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

export DOTFILES_DIR

# Make utilities available
PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)
ls -A "$DOTFILES_DIR/system" | while read DOTFILE
do
  . "$DOTFILES_DIR/system/$DOTFILE"
done


# Wrap up

unset CURRENT_SCRIPT SCRIPT_PATH DOTFILE

# Remove duplicates (preserving prepended items)
# Source: http://unix.stackexchange.com/a/40755

PATH=$(echo -n $PATH | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')

# Wrap up

export PATH
