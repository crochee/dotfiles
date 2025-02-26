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

install_clipboard() {
    # 检查系统是否为WSL
    # if [ -f "/proc/version" ]; then
    # 	if grep -q "microsoft" "/proc/version"; then
    # 		echo "system is WSL"
    # 		if has_cmd "win32yank.exe"; then
    # 			return 0
    # 		fi
    # 		echo "install clipboard..."
    # 		#下载win32yank.exe,参考http://github.com/equalsraf/win32yank/releases 将执行文件放置于/usr/local/bin/目录下
    # 		curl -sL https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x86.zip -o ~/Downloads/win32yank-x86.zip
    # 		unzip ~/Downloads/win32yank-x86.zip -d ~/Downloads/win32yank/
    # 		chmod +x ~/Downloads/win32yank/win32yank.exe
    # 		sudo mv ~/Downloads/win32yank/win32yank.exe /usr/local/bin
    # 	else
    echo "system is Linux"
    if has_cmd "xclip"; then
        return 0
    fi
    echo "install clipboard..."
    sudo apt-get install xclip -y
    # fi
    echo "install clipboard done."
    # else
    # 	echo "unknown system type"
    # 	exit 1
    # fi
}

install_neovim() {
    if ! has_cmd "nvim"; then
        # install neovim
        echo "install neovim..."
        curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz | tar -xzv -C ~/.local/bin
        #curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz | tar -xzv -C ~/.local/bin
        # sudo apt-get install -y neovim
        echo "install neovim done."
        source "$HOME/.bashrc"
    fi
}

install_nodejs() {
    if ! has_cmd "node"; then
        echo "install nodejs done."
        sudo apt-get install -y ca-certificates curl gnupg
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        local NODE_MAJOR=20
        sudo echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        sudo apt-get update
        sudo apt-get install -y nodejs
        echo "install nodejs v${NODE_MAJOR}.x done."
        unset NODE_MAJOR
        source "$HOME/.bashrc"
    fi
}

install_nerdfonts() {
    # see https://www.nerdfonts.com/font-downloads
    if [ -d "/usr/share/fonts/FantasqueSansMono" ]; then
        return 0
    fi
    echo "install Fantasque Sans Mono nerd font..."
    sudo mkdir -p /usr/share/fonts
    sudo unzip "$SCRIPT_PATH/nerdfonts/FantasqueSansMono.zip" -d /usr/share/fonts/FantasqueSansMono
    cd /usr/share/fonts/FantasqueSansMono
    if ! has_cmd "mkfontscale"; then
        sudo apt-get install -y ttf-mscorefonts-installer
    fi
    # 生成核心字体信息
    sudo mkfontscale
    # 生成字体文件
    sudo mkfontdir
    if ! has_cmd "fc-cache"; then
        sudo apt-get install -y fontconfig
    fi
    # 更新/刷新系统字体缓存
    sudo fc-cache -fv
    cd "$SCRIPT_PATH"
    echo "install Fantasque Sans Mono nerd font done."
}

install_rust() {
    if ! has_cmd "cargo"; then
        echo "install rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        echo "install rust done."
        source "$HOME/.bashrc"
    fi
}

install_go() {
    if ! has_cmd "go"; then
        echo "install go..."
        mkdir -p ~/.config/golang/
        local GO_VERSION="1.22.7"
        cd ~/Downloads/
        wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
        tar -C ~/.config/golang -xzf go${GO_VERSION}.linux-amd64.tar.gz
        rm -rf go${GO_VERSION}.linux-amd64.tar.gz
        cd "$SCRIPT_PATH"
        unset GO_VERSION
        echo "install go done."
        source "$HOME/.bashrc"
    fi
}

install_python3() {
    if ! has_cmd "python3"; then
        echo "install python3..."
        sudo apt-get install -y python3 python3.11-venv python3-pip
        echo "install python3 done."
        source "$HOME/.bashrc"
    fi
}

install_wezterm() {
    if ! has_cmd "wezterm"; then
        echo "install wezterm..."
        cd ~/Downloads/
        curl -LO https://github.com/wez/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203-110809-5046fc22.Ubuntu22.04.deb
        sudo dpkg -i ./wezterm-20240203-110809-5046fc22.Ubuntu22.04.deb
        cd "$SCRIPT_PATH"
        echo "install wezterm done."
    fi
}

install_tools() {
    if has_cmd "go"; then
        if ! has_cmd "mockgen"; then
            echo "install mockgen..."
            go install go.uber.org/mock/mockgen@latest
            echo "install mockgen done."
        fi
        if ! has_cmd "lazygit"; then
            echo "install lazygit..."
            go install github.com/jesseduffield/lazygit@latest
            echo "install lazygit done."
        fi
        if ! has_cmd "cliphist"; then
            echo "install cliphist..."
            go install go.senan.xyz/cliphist@latest
            echo "install cliphist done."
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
        fi
    fi
}

install_mycli() {
    if has_cmd "pip" && ! has_cmd "mycli"; then
        echo "install mycli..."
        sudo pip install mycli
        echo "install mycli done."
    fi
}

install_fcitx() {
    echo "install fcitx5..."
    sudo apt install fcitx5 fcitx5-chinese-addons
    echo "install fcitx5 done."
}

install_vpn() {
    echo "install vpn..."
    sudo apt install openvpn
    echo "install vpn done."
}

install_rsync() {
    echo "install rsync..."
    sudo apt install rsync
    echo "install rsync done."
}

install() {
    for command in "$@"; do
        eval "install_$command"
    done
}

show_menu() {
    sudo apt update
    sudo apt upgrade
    sudo apt -y install curl wget gcc g++
    mkdir -p ~/Downloads
    mkdir -p ~/.local/bin
    echo "================INSTALL================="
    echo "please select go, rust, python3, clipboard, nodejs, neovim, mycli, wezterm, tools or quit:"
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
