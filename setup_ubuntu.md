## ubuntu 环境配置

* 安装 sogou 拼音输入法
  * 从 sogou 官网下载 deb 安装包
  * sudo apt-get install gdebi
  * sudo gdebi sogou-xxxxx

#### ubuntu 主题

* [Flatabulous](https://github.com/anmoljagetia/Flatabulous)

#### 工作区快捷键

* Ctrl+Alt+方向键   在各个工作区移动
* Shift+Ctrl+Alt+方向键     当前程序移动到别的工作区

#### 防止休眠小程序

* sudo apt-get install caffine
> dash 搜索 gnome-session 添加 /usr/bin/caffeine-indicator 开机启动

#### asciinema 终端记录

* sudo apt-get install asciinema

#### todolist

* todotxt.com

## 开发环境配置

git neovim python2/3 (dev,pip) zsh tmux nodejs

#### 安装 git

* sudo apt-get install git
* git clone https://github.com/iamcco/dotfiles

#### 安装 nodejs

* https://github.com/nodesource/distributions

#### 安装 tmux

* sudo apt-get install tmux

#### 安装 neovim

* sudo apt-get install software-properties-common
* sudo add-apt-repository ppa:neovim-ppa/unstable
* sudo apt-get update
* sudo apt-get install neovim xclip
* sudo apt-get install python-dev python-pip python3-dev python3-pip
* ln -s dotfiles/nvim .config/nvim

> :PlugInstall
> :UpdateRemotePlugins

**neovim 配置**
```
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --config vi
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --config vim
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
sudo update-alternatives --config editor
```

#### 安装字体 font-manager

字体使用 [fantasque-sans](https://github.com/belluzj/fantasque-sans)

```
mkdir ~/.fonts
mv fontName ~/.fonts
cd ~/.fonts/fontName
mkfontdir
mkfontscale
fc-cache -fv
```

#### 安装 oh-my-zsh

```
sudo apt-get install zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
rm ~/.zshrc
ln -s ~/dotfiles/.zshrc ~/.zshrc
chsh -s /bin/zsh
```
#### TODO List

* [ ] fzf
* [ ] ctrlSpace
