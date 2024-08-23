#!/usr/bin/env bash

unset COLUMNS

SOURCE="git@github.com:crochee/dotfiles.git"
TARGET="$HOME/.dotfiles"

msg() {
    echo -en "$*"
}
# title
msg_title() {
    echo -en "\n========"
    echo -en " $1 "
    echo "========"
}

check_cmd() {
    idx=1
    for command in "$@"; do
        echo -en "${idx}. "
        msg "$command"
        if type "$command" >/dev/null 2>&1; then
            msg " √\n"
        else
            msg " ✘\n"
            return 1
        fi
        ((idx++))
    done
}

mkdir_backup() {
    msg "create backup dir: $1"
    if mkdir "$1" >/dev/null 2>&1; then
        msg " √\n"
    else
        msg " ✘\n"
        exit 1
    fi
}

mk_symlink() {
    if [ -e "$1" ]; then
        # check dotfile is exists
        if [ -e "$2" ] && [ -L "$2" ]; then
            # create backup dir if not exists
            backup_dir="$HOME/backup_$(date +%Y-%m-%d_%H-%M-%S)"
            if [ ! -d "$backup_dir" ]; then mkdir_backup "$backup_dir"; fi
            # backup dotfile
            msg "mv $2 to $backup_dir"
            if mv "$2" "$backup_dir/" >/dev/null 2>&1; then
                msg " √\n"
            else
                msg " ✘\n"
            fi
        fi
        msg "link $1 to $2"
        if ln -s "$1" "$2" >/dev/null 2>&1; then
            msg " √\n"
        else
            msg " ✘\n"
        fi
    else
        msg "file $1 is not exists\n"
    fi
}

clone_repo() {
    TARBALL="$SOURCE/tarball/master"
    TAR_CMD="tar -xzv -C $TARGET --strip-components=1 --exclude='.gitignore'"
    if check_cmd "git"; then
        CMD="git clone $SOURCE $TARGET"
    elif check_cmd "curl"; then
        CMD="curl -#L $TARBALL | $TAR_CMD"
    elif check_cmd "wget"; then
        CMD="wget --no-check-certificate -O - $TARBALL | $TAR_CMD"
    fi

    if [ -z "$CMD" ]; then
        msg "No git, curl or wget available. Aborting."
    else
        msg "clone dotfiles...\n"
        mkdir -p "$TARGET"
        if ! eval "$CMD"; then return 1; fi
        msg "clone dotfiles done!\n"
        return 0
    fi
    return 1
}

check_repo() {
    msg "check ${TARGET}"
    if [ -e "$TARGET" ]; then
        msg " √\n"
        return 0
    else
        msg " ✘\n"
        if clone_repo; then
            return 0
        else
            return 1
        fi
    fi
}

install_dotfiles() {
    msg "install dotfiles...\n"
    local path_to_dotfiles="${TARGET}/dotfiles"
    find "${path_to_dotfiles}" -type f | while read -r file; do
        mk_symlink "${file}" "${HOME}/$(basename "$file")"
    done
    msg "install dotfiles done!\n"
}

install_config() {
    msg "installing config...\n"
    local path_to_config="${HOME}/.config"
    msg "check ${path_to_config}"
    if [ -e "$path_to_config" ]; then
        msg " √\n"
    else
        msg " ✘\n"
        msg "mkdir directory ${path_to_config}"
        if mkdir -p "${path_to_config}" >/dev/null 2>&1; then
            msg " √\n"
        else
            msg " ✘\n"
            exit 1
        fi
    fi
    msg "installing neovim config...\n"
    mk_symlink "${TARGET}/nvim" "${path_to_config}/nvim"
    msg "install neovim config done!\n"

    msg "installing wezterm config...\n"
    mk_symlink "${TARGET}/wezterm" "${path_to_config}/wezterm"
    msg "install wezterm config done!\n"
}

install_cargo() {
    source "$HOME/.bashrc"
    msg "install cargo...\n"
    local path_to_cargo="${CARGO_HOME}"
    msg "check ${path_to_cargo}"
    if [ -e "$path_to_cargo" ]; then
        msg " √\n"
    else
        msg " ✘\n"
        msg "mkdir directory ${path_to_cargo}"
        if mkdir -p "${path_to_cargo}" >/dev/null 2>&1; then
            msg " √\n"
        else
            msg " ✘\n"
            exit 1
        fi
    fi
    mk_symlink "${TARGET}/cargo/config.toml" "${path_to_cargo}/config.toml"
    msg "install cargo done!\n"
}

install_zk() {
    msg "installing zk...\n"
    local path_to_notes="${HOME}/.config/notes"
    msg "check ${path_to_notes}"
    if [ -e "$path_to_notes" ]; then
        msg " √\n"
    else
        msg " ✘\n"
        msg "mkdir directory ${path_to_notes}"
        if mkdir -p "${path_to_notes}" >/dev/null 2>&1; then
            msg " √\n"
        else
            msg " ✘\n"
            exit 1
        fi
    fi
    mk_symlink "${TARGET}/zk" "${path_to_notes}/.zk"
    msg "install zk done!\n"
}

init_bashrc() {
    FILE_PATH="$HOME/.bashrc"
    if [ ! -f "$FILE_PATH" ]; then
        touch "$FILE_PATH"
        echo "source $HOME/.dotfiles/.bashrc" >>"$FILE_PATH"
    else
        if grep -q "source $HOME/.dotfiles/.bashrc" "$FILE_PATH"; then
            return
        else
            echo "source $HOME/.dotfiles/.bashrc" >>"$FILE_PATH"
        fi
    fi
}

install() {
    case $1 in
    1) check_repo && install_config ;;
    2) check_repo && install_dotfiles ;;
    3) check_repo && install_dotfiles && install_config ;;
    4) check_repo && install_zk ;;
    5) check_repo && install_cargo ;;
    *) msg "your option is invalid! Goodbye!" ;;
    esac
}

show_menu() {
    msg_title "INSTALL"
    echo "1) install config"
    echo "2) install dotfiles"
    echo "3) install dotfiles and config"
    echo "4) install zk"
    echo "5) install cargo config"
    echo -n "select: "
    read -r num
    install "$num"
}

init_bashrc
find "${TARGET}/bin" -type f -exec chmod a+x {} +
if [ "$#" -eq 0 ]; then
    show_menu
else
    install "$@"
fi

unset SCRIPT_PATH TARGET FILE_PATH
