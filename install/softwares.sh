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
    mkdir -p /usr/share/fonts
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

install_ubuntu_theme(){
    echo "install ubuntu theme..."
    apt-get install unity-tweak-tool

    wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
    sh -c 'echo "deb http://archive.getdeb.net/ubuntu xenial-getdeb apps" >> /etc/apt/sources.list.d/getdeb.list'
    apt-get update
    apt-get install ubuntu-tweak

    add-apt-repository ppa:noobslab/themes
    apt-get update
    apt-get install flatabulous-theme

    add-apt-repository ppa:noobslab/icons
    apt-get update
    apt-get install ultra-flat-icons

    echo "install ubuntu theme done."
}

install_sogou(){
    echo "install sogou..."
    wget https://ime-sec.gtimg.com/202309241820/bef68502303ef2670536016347d80024/pc/dl/gzindex/1680521603/sogoupinyin_4.2.1.145_amd64.deb  -P ~/Downloads/
    apt-get install gdebi
    gdebi ~/Downloads/sogoupinyin_4.2.1.145_amd64.deb
    echo "install sogou done."
}

install(){
    for command in $*
    do
        eval "install_$command"
    done
}

show_menu(){
    mkdir -p ~/Downloads
    echo "================INSTALL================="
    echo "please select zk, clipboard, neovim, zsh, nodejs, chrome, fonts, ubuntu theme, sogou: "
    echo -n "select: "
    read num
    install $num
}

show_menu
