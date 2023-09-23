#!/usr/bin/env bash

unset COLUMNS

SOURCE="https://github.com/crochee/dotfiles"
TARGET="$HOME/.dotfiles"

msg() {
    echo -en "$*"
}
# title
 msg_title() {
    echo -en "\n========"; echo -en " $1 "; echo "========"
}

check_cmd() {
    idx=1
    for command in $*
    do
        echo -en "${idx}. "; msg $command
        if type $command > /dev/null 2>&1
        then
            msg " √\n"
        else
            msg " ✘\n"
            return 1
        fi
        ((idx++))
    done
}

mkdir_backup() {
    msg "create backup dir:" $1
    if mkdir "$1" > /dev/null 2>&1
    then
        msg " √\n"
    else
        msg " ✘\n"
        exit 1
    fi
}

mk_symlink() {
    if [ -e "$1" ]
    then
        # check dotfile is exists
        if [ -e $2 -o -L $2 ]
        then
            # create backup dir if not exists
            backup_dir="$HOME/backup_`date +%Y-%m-%d_%H-%M-%S`"
            if [ ! -d $backup_dir ]; then mkdir_backup $backup_dir; fi
            # backup dotfile
            msg "mv $2 to $backup_dir"
            if mv "$2" "$backup_dir/" > /dev/null 2>&1
            then
                msg "√\n"
            else
                msg "✘\n"
            fi
        fi
        msg "link $1 to $2"
        if ln -s "$1" "$2" > /dev/null 2>&1
        then
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
    TAR_CMD="tar -xzv -C "$TARGET" --strip-components=1 --exclude='.gitignore'"
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
        eval "$CMD"
        [[ $? -ne 0 ]] && return 1
        msg "clone dotfiles done!\n"
        return 0
    fi
    return 1
}

check_repo() {
    msg "check ${TARGET}\n"
        if [ -e $TARGET ]
        then
            msg " √\n"
            return 0
        else
            msg " ✘\n"
            if clone_repo
            then
                return 0
            else
                return 1
            fi
        fi
}

install_dotfiles(){
    msg "installing dotfiles...\n"
    local path_to_dotfiles="${TARGET}/dotfiles"
    ls "${path_to_dotfiles}" | while read item
    do
        mk_symlink "${path_to_dotfiles}/${item}" "${HOME}/.${item}"
    done
    msg "install dotfiles done!\n"
}

install_neovim_config(){
    msg "installing neovim config...\n"
    local path_to_nvim="${HOME}/.config"
    msg "check ${path_to_nvim}\n"
    if [ -e $path_to_nvim ]
    then
        msg " √\n"
    else
        msg " ✘\n"
        msg "mkdir directory ${path_to_nvim}"
        if mkdir -p "${path_to_nvim}" > /dev/null 2>&1
        then
            msg " √\n"
        else
            msg " ✘\n"
            exit 1
        fi
    fi
    mk_symlink "${TARGET}/nvim" "${HOME}/.config/nvim"
    msg "install neovim config done!\n"
}

show_menu(){
    msg_title "INSTALL"
    echo "1) install neovim config"
    echo "2) install dotfiles"
    echo "3) install dotfiles and neovim config"
    echo "4) check git"
    echo -n "select: "
    read num
    case $num in
        1) check_repo && install_neovim_config ;;
        2) check_repo && install_dotfiles ;;
        3) check_repo && install_dotfiles && install_neovim_config ;;
        4) check_cmd git ;;
        *) log "your option is invalid! Goodbye!";;
    esac
}

show_menu
