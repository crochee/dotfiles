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
    mv ~/Downloads/zk /usr/local/bin
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
            mv ~/Downloads/win32yank/win32yank.exe /usr/local/bin
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
    # curl -L  https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz | tar -xzv -C ~/Downloads/
    # sudo chmod a+x ~/Downloads/nvim
    # sudo mv ~/Downloads/nvim  /usr/bin/
    sudo apt-get install -y neovim ripgrep
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
    mkdir -p /usr/share/fonts
    sudo unzip "$SCRIPT_PATH/nerdfonts/FantasqueSansMono.zip" -d /usr/share/fonts/FantasqueSansMono
    cd /usr/share/fonts/FantasqueSansMono
    # 生成核心字体信息
    sudo mkfontscale
    # 生成字体文件
    sudo mkfontdir
    # 更新/刷新系统字体缓存
    sudo fc-cache -fv
    cd $SCRIPT_PATH
    echo "install Fantasque Sans Mono nerd font done."
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
    echo "please select zk, clipboard, neovim, zsh, nodejs, nerdfonts, tmux, or quit:"
    echo -n "select: "
    read num
    install $num
}

show_menu
