#!/usr/bin/env bash

set -e

# change cwd to scripts directory
echo "$NC change cwd to $SCRIPT_PATH $NC"
cd $SCRIPT_PATH

has_cmd() {
    echo -en "${idx}. $1"
    if type $1 > /dev/null 2>&1
    then
        echo " √"
        return 1
    else
        echo " ✘"
        return 0
    fi
}

install_zk(){
    if has_cmd "zk"; then
        return 0
    fi
    echo "install zk..."
    curl -#L https://github.com/mickael-menu/zk/releases/download/v0.14.0/zk-v0.14.0-linux-amd64.tar.gz | tar -xzv -C ~/Downloads/
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
            curl -sL https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x86.zip | unzip -o -d ~/Downloads/
            chmod +x ~/Downloads/win32yank-x86/win32yank.exe
            mv ~/Downloads/win32yank-x86/win32yank.exe /usr/local/bin
        else
            echo "system is Linux"
            if has_cmd "xclip"; then
                return 0
            fi
            echo "install clipboard..."
            apt-get install xclip
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
    add-apt-repository ppa:neovim-ppa/unstable
    apt-get update
    apt-get install neovim
    # apt-get install python-pip python3-pip python-dev python-pip python3-dev python3-pip
    echo "install neovim done."
}

install_zsh() {
    if has_cmd "zsh"; then
        return 0
    fi
    # install zsh
    echo "install zsh and setup oh_my_zsh..."
    apt-get install zsh
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
    echo "install nodejs v4.x..."
    curl -sL https://deb.nodesource.com/setup_4.x | -E bash -
    apt-get install -y nodejs

    # installl global nodejs package
    cat "$SCRIPT_PATH/sh/nodejs_global_package.txt" | while read node_package_name
    do
        echo "install $node_package_name"
        npm install -g $node_package_name
    done
}

install_chrome() {
    if has_cmd "google-chrome"; then
        return 0
    fi
    # install chrome
    echo "install chrome..."
    wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub  | apt-key add -
    apt-get update
    apt-get install google-chrome-stable
    echo "install chrome done."
}

install_fonts() {
    if [ -d "/usr/share/fonts/FantasqueSansMono-Normal" ]; then
        return 0
    fi
    echo "install Fantasque Sans Mono normal font..."
    unzip "$SCRIPT_PATH/fonts/FantasqueSansMono-Normal.zip" -d /usr/share/fonts/FantasqueSansMono-Normal
    cd /usr/share/fonts/FantasqueSansMono-Normal
    # 生成核心字体信息
    mkfontscale
    # 生成字体文件
    mkfontdir
    # 更新/刷新系统字体缓存
    fc-cache -fv
    cd $SCRIPT_PATH
    echo "install Fantasque Sans Mono normal font done."
}

install(){
    idx=1
    for command in $*
    do
        echo "${idx}. $command"
        eval "install_$command"
        ((idx++))
    done
}

show_menu(){
    mkdir -p ~/Downloads
    echo "================INSTALL================="
    echo "please select zk, clipboard, neovim, zsh, nodejs, chrome, fonts: "
    echo -n "select: "
    read num
    install $num
}

show_menu
