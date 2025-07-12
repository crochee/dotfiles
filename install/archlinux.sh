#!/usr/bin/env bash

set -e

# change cwd to scripts directory
SCRIPT_PATH=$(dirname "$(dirname "${BASH_SOURCE[0]}")")
echo "change cwd to $SCRIPT_PATH"
cd "$SCRIPT_PATH"

has_cmd() {
    echo -n "$*"
    if type "$*" >/dev/null 2>&1; then
        echo " √"
    else
        echo " ✘"
        return 1
    fi
}

install_rust() {
    if ! has_cmd "cargo" && [ -n "$CARGO_HOME" ]; then
        echo "install rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        echo "install rust done."
        source "$HOME/.bashrc"
    fi
}

install_go() {
    if ! has_cmd "go" && [ -n "$GOROOT" ] && test -d "$GOROOT"; then
        echo "install go..."
        local GO_VERSION="1.24.5"
        cd ~/Downloads/
        wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
        tar -C "${GOROOT}" -xzf go${GO_VERSION}.linux-amd64.tar.gz
        rm -rf go${GO_VERSION}.linux-amd64.tar.gz
        mv "${GOROOT}/go" "$GOROOT/go${GO_VERSION}"
        cd "$SCRIPT_PATH"
        unset GO_VERSION
        echo "install go done."
        source "$HOME/.bashrc"
    fi
}

install_python() {
    if ! has_cmd "python"; then
        echo "install python..."
        sudo pacman -S python
    fi
}

install_rsync() {
    if ! has_cmd "rsync"; then
        echo "install rsync..."
        sudo pacman -S rsync
    fi
}

install_nodejs() {
    if ! has_cmd "node"; then
        echo "install nodejs..."
        sudo pacman -S nodejs
    fi
}

install_java() {
    if ! has_cmd "java"; then
        echo "install java..."
        sudo pacman -S jdk17-openjdk
        echo "install java done."
    fi
}

install_tools() {
    if has_cmd "go"; then
        if ! has_cmd "lazygit"; then
            echo "install lazygit..."
            go install github.com/jesseduffield/lazygit@latest
            echo "install lazygit done."
        fi
        if ! has_cmd "kind"; then
            echo "install kind..."
            go install sigs.k8s.io/kind@latest
            echo "install kind done."
        fi
    fi
    if has_cmd "cargo"; then
        if ! has_cmd "bat"; then
            echo "install bat..."
            cargo install --locked bat
            echo "install bat done."
        fi
        # install ripgrep
        if ! has_cmd "rg"; then
            echo "install ripgrep..."
            cargo install ripgrep
            echo "install ripgrep done."
        fi
        if ! has_cmd "fd"; then
            echo "install fd..."
            cargo install fd-find
            echo "install fd done."
        fi
        if ! has_cmd "zoxide"; then
            echo "install zoxide..."
            cargo install zoxide
            echo "install zoxide done."
        fi
        if ! has_cmd "mcfly"; then
            echo "install mcfly..."
            cargo install mcfly
            echo "install mcfly done."
        fi
        if ! has_cmd "uv"; then
            echo "install uv..."
            cargo install --git https://github.com/astral-sh/uv uv
            echo "install uv done."
            if ! has_cmd "mycli"; then
                echo "install mycli..."
                source "$HOME/.venv/bin/activate"
                uv pip install mycli
                echo "install mycli done."
            fi
        fi
    fi
}

install() {
    for command in "$@"; do
        eval "install_$command"
    done
}

show_menu() {
    sudo pacman -S base-devel curl wget unzip gcc
    mkdir -p ~/Downloads
    mkdir -p ~/.local/bin
    echo "================INSTALL================="
    echo "please select go, rust, python, nodejs, java, wl-clipboard, rsync, tools or quit:"
    echo -n "select: "
    read -r num
    install "$num"
}

if [ "$#" -eq 0 ]; then
    show_menu
else
    mkdir -p ~/Downloads
    install "$@"
fi

unset SCRIPT_PATH
