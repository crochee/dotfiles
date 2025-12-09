# 使用 Arch Linux 作为基础镜像
FROM archlinux:latest

# 维护者信息
LABEL maintainer="crochee <your.email@example.com>"
LABEL description="Arch Linux 开发环境"
LABEL version="1.0.0"

# 设置环境变量
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color
ENV HOME=/root

# 更新系统并安装基础软件包
RUN pacman -Sy --noconfirm --needed \
    base-devel \
    git \
    curl \
    wget \
    neovim \
    bash-completion \
    zsh \
    tmux \
    unzip \
    tar \
    gzip \
    bzip2 \
    rsync \
    tree \
    htop \
    iftop \
    iotop \
    net-tools \
    openssh \
    python \
    go \
    rust \
    cargo \
    nodejs \
    npm \
    jdk17-openjdk \
    maven \
    gradle \
    docker \
    kubectl \
    kubectx \
    helm \
    && pacman -Scc --noconfirm

# 配置 Git
RUN git config --global user.name "crochee"
RUN git config --global user.email "your.email@example.com"
RUN git config --global core.editor "vim"
RUN git config --global color.ui true
RUN git config --global alias.co checkout
RUN git config --global alias.br branch
RUN git config --global alias.ci commit
RUN git config --global alias.st status
RUN git config --global alias.lg "log --oneline --graph --decorate --all"

# 配置 Go 环境
ENV GOPATH=/root/go
ENV PATH=$PATH:$GOPATH/bin:/usr/local/go/bin
RUN mkdir -p $GOPATH/src $GOPATH/bin

# 配置 Rust 环境
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH=$PATH:$CARGO_HOME/bin
RUN rustup default stable
RUN cargo install bat ripgrep fd-find zoxide mcfly lazygit

# 配置 Node.js 环境
RUN npm config set prefix "$HOME/.npm-global"
ENV PATH=$PATH:$HOME/.npm-global/bin
RUN npm install -g yarn pnpm nrm

# 配置 Python 环境
RUN pip install --upgrade pip
RUN pip install virtualenvwrapper ipython mycli

# 配置 Java 环境
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

# 克隆 dotfiles 仓库
RUN git clone https://github.com/crochee/dotfiles.git $HOME/.dotfiles

# 安装 dotfiles 配置
RUN cd $HOME/.dotfiles && ./install/install.sh 3

# 配置 Bash
RUN echo "source $HOME/.dotfiles/.bashrc" >> $HOME/.bashrc

# 配置 Zsh (可选)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# 配置 Vim
RUN mkdir -p $HOME/.vim/pack/plugins/start

# 暴露端口
EXPOSE 22 80 443 8080 3000 9000

# 设置工作目录
WORKDIR $HOME

# 启动命令
CMD ["bash"]
