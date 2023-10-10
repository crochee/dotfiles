#!/usr/bin/env bash

set -e

# change cwd to scripts directory
SCRIPT_PATH=$(dirname $(dirname "$BASH_SOURCE"))
echo "change cwd to $SCRIPT_PATH"
cd $SCRIPT_PATH

has_cmd() {
    echo -n "$*"
    if type $* > /dev/null 2>&1
    then
        echo " √"
    else
        echo " ✘"
        return 1
    fi
}

install_zk(){
    if has_cmd "zk"; then
        return 0
    fi
    echo "install zk..."
    curl -L https://github.com/mickael-menu/zk/releases/download/v0.14.0/zk-v0.14.0-linux-amd64.tar.gz | tar -xzv -C ~/Downloads/
    chmod a+x ~/Downloads/zk
    sudo mv ~/Downloads/zk /usr/local/bin
    if has_cmd "cargo"; then
        cargo install --locked bat
    else
        sudo apt install -y bat
    fi
    echo "install zk done."
}

install_clipboard() {
    # 检查系统是否为WSL
    if [ -f "/proc/version" ]; then
        if grep -q "microsoft" "/proc/version"; then
            echo "system is WSL"
            if has_cmd "win32yank.exe"; then
                return 0
            fi
            echo "install clipboard..."
            #下载win32yank.exe,参考http://github.com/equalsraf/win32yank/releases 将执行文件放置于/usr/local/bin/目录下
            curl -sL https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x86.zip -o  ~/Downloads/win32yank-x86.zip
            unzip ~/Downloads/win32yank-x86.zip -d  ~/Downloads/win32yank/
            chmod +x ~/Downloads/win32yank/win32yank.exe
            sudo mv ~/Downloads/win32yank/win32yank.exe /usr/local/bin
        else
            echo "system is Linux"
            if has_cmd "xclip"; then
                return 0
            fi
            echo "install clipboard..."
            sudo apt-get install xclip
        fi
        echo "install clipboard done."
    else
        echo "unknown system type"
        exit 1
    fi
}

install_neovim() {
    if has_cmd "nvim"; then
        return 0
    fi
    # install neovim
    echo "install neovim..."
    curl -L  https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz | tar -xzv -C ~/Downloads/
    mkdir -p $HOME/.nvim
    mv ~/Downloads/nvim-linux64 $HOME/.nvim/
    # sudo apt-get install -y neovim
    # install ripgrep
    if has_cmd "cargo"; then
      cargo install ripgrep
    else
      sudo apt-get install -y ripgrep
    fi
    # apt-get install python-pip python3-pip python-dev python-pip python3-dev python3-pip
    echo "install neovim done."
}

install_zsh() {
    if has_cmd "zsh"; then
        return 0
    fi
    # install zsh
    echo "install zsh and setup oh_my_zsh..."
    sudo apt-get install zsh
    # change default shell
    chsh -s $(which zsh)
    # setup oh_my_zsh
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # curl -sS https://starship.rs/install.sh | sh
    echo "install zsh and setup oh_my_zsh done."
}

install_nodejs() {
    if has_cmd "node"; then
        return 0
    fi
    # install nodejs v4.x
    echo "install nodejs v4.x and npm..."
    #curl -sL https://deb.nodesource.com/setup_4.x | -E bash -
    sudo apt-get install -y nodejs npm
    echo "install nodejs and npm done."
}

install_tmux() {
    if has_cmd "tmux"; then
        return 0
    fi
    # install nodejs v4.x
    echo "install tmux..."
    #curl -sL https://deb.nodesource.com/setup_4.x | -E bash -
    sudo apt-get install -y tmux
    echo "install tmux done."
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
    if ! has_cmd "mkfontscale" ;then
       sudo apt-get install -y ttf-mscorefonts-installer
    fi
    # 生成核心字体信息
    sudo mkfontscale
    # 生成字体文件
    sudo mkfontdir
    if ! has_cmd "fc-cache" ;then
       sudo apt-get install -y fontconfig 
    fi
    # 更新/刷新系统字体缓存
    sudo fc-cache -fv
    cd $SCRIPT_PATH
    echo "install Fantasque Sans Mono nerd font done."
}

install_rust() {
    if has_cmd "cargo"; then
        return 0
    fi
    echo "install rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    echo "install rust done."
}

install_go(){
    if has_cmd "go"; then
        return 0
    fi
    echo "install go..."
    mkdir -p ~/.config/golang/
    local GO_VERSION="1.17.13"
    wget --no-check-certificate -O - https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -C ~/.config/golang -xzf
    echo "install go done."
}

install(){
    for command in $*
    do
        eval "install_$command"
    done
}

show_menu(){
    sudo apt update
    sudo apt upgrade
    sudo apt -y install curl wget
    mkdir -p ~/Downloads
    echo "================INSTALL================="
    echo "please select go, rust, zk, clipboard, neovim, zsh, nodejs, nerdfonts, tmux, or quit:"
    echo -n "select: "
    read num
    install $num
}

show_menu
