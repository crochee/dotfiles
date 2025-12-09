# dotfiles

个人开发环境配置文件集合，用于快速搭建和管理开发环境。

## 功能介绍

### 🎯 核心功能
- **多语言支持**：Go、Rust、TypeScript/JavaScript、Python3、Shell、Java
- **跨平台兼容**：支持 Arch Linux 等多种 Linux 发行版
- **模块化设计**：按功能和应用程序分类管理配置文件
- **自动化安装**：一键安装和更新配置
- **安全可靠**：配置文件备份机制，防止数据丢失

### 📦 包含的配置

#### 开发环境
- **Shell**：Bash 配置
- **编辑器**：VS Code、Neovim 配置
- **终端**：Wezterm终端模拟器配置
- **版本控制**：Git 配置

#### 语言环境
- **Go**：GOPATH、GOROOT 配置，常用工具安装
- **Rust**：Cargo 配置，常用工具安装
- **Node.js**：NPM/Yarn 配置，常用工具安装
- **Python**：虚拟环境配置，常用工具安装
- **Java**：JDK 配置，Maven/Gradle 配置

#### 开发工具
- **容器**：Docker 配置
- **Kubernetes**：Kubectl 配置
- **数据库**：MySQL、PostgreSQL 客户端配置
- **文档**：Markdown 工具配置
- **其他**：各种开发辅助工具配置

## 快速开始

### 安装前准备

```bash
sudo pacman -S openssh

ssh-keygen -t ed25519 -C "crochee@home"
```

### 安装

#### 方式一：一键安装
```shell
bash -c "$(curl -fsSl https://raw.githubusercontent.com/crochee/dotfiles/master/install/install.sh)"
```

#### 方式二：手动安装
1. 克隆仓库
```shell
git clone https://github.com/crochee/dotfiles.git ~/.dotfiles
```

2. 运行安装脚本
```shell
cd ~/.dotfiles
./install/install.sh
```

### Arch Linux 特定安装
```shell
cd ~/.dotfiles
./install/archlinux.sh
```

## 使用说明

### 交互式安装

运行安装脚本后，会显示交互式菜单：

```
1) 安装配置文件
2) 安装 dotfiles
3) 安装 dotfiles 和配置文件
4) 安装 zk 配置
5) 安装共享文件
6) 安装 codex 配置

请选择安装选项 [1-6]: 
```

### 命令行安装

可以直接指定安装选项：

```shell
# 安装配置文件
./install/install.sh 1

# 安装 dotfiles 和配置文件
./install/install.sh 3

# 显示帮助信息
./install/install.sh --help
```

### Arch Linux 安装选项

```shell
# 安装特定组件
./install/archlinux.sh go rust python

# 安装所有组件
./install/archlinux.sh all

# 显示帮助信息
./install/archlinux.sh --help
```

## 配置示例

### Git 配置

```shell
# ~/.gitconfig 示例
[user]
    name = Your Name
    email = your.email@example.com
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    lg = log --oneline --graph --decorate --all
```

### Go 配置

```shell
# ~/.bashrc 中的 Go 配置
export GOPATH=$HOME/.config/gopath
export PATH=$PATH:$GOPATH/bin:$GOPATH/bin
```

### Rust 配置

```shell
# ~/.cargo/config.toml 示例
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
```

## 目录结构

```
dotfiles/
├── .bashrc              # Bash 配置文件
├── bin/                 # 可执行脚本
├── config/              # 应用程序配置
├── Dockerfile           # Docker 配置
├── dotfiles/            # 用户目录配置文件
├── install/             # 安装脚本
│   ├── archlinux.sh     # Arch Linux 安装脚本
│   ├── install.sh       # 主安装脚本
│   └── softwares.sh     # 软件安装脚本
├── k8scnf/              # Kubernetes 配置
├── README.md            # 项目说明
├── scripts/             # 辅助脚本
├── setup_ubuntu.md      # Ubuntu 安装说明
├── share/               # 共享文件
├── src/                 # 源代码
├── system/              # 系统配置
├── test.ps1             # 测试脚本
└── zk/                  # ZK 配置
```

## 配置管理

### 更新配置

```shell
# 进入 dotfiles 目录
cd ~/.dotfiles

# 拉取最新配置
git pull

# 重新运行安装脚本
./install/install.sh
```

### 自定义配置

1. 克隆仓库后，可以根据自己的需求修改配置文件
2. 提交修改到本地仓库
3. 推送到远程仓库，备份自己的配置

```shell
# 提交修改
git add .
git commit -m "Update configuration"
git push origin master
```

### 备份和恢复

安装过程中，脚本会自动备份原有的配置文件到 `~/.dotfiles/backup_<timestamp>` 目录。

如果需要恢复配置，可以：

1. 查看备份目录
```shell
ls -la ~/.dotfiles/backup_*
```

2. 手动恢复配置文件
```shell
cp ~/.dotfiles/backup_2023-01-01_12-00-00/.bashrc ~/.bashrc
```

## 开发指南

### 贡献代码

1. Fork 仓库
2. 创建特性分支
```shell
git checkout -b feature/your-feature
```

3. 提交修改
```shell
git add .
git commit -m "Add your feature"
```

4. 推送到远程仓库
```shell
git push origin feature/your-feature
```

5. 创建 Pull Request

### 代码规范

- Shell 脚本使用 ShellCheck 检查
- 配置文件使用统一的格式
- 代码注释清晰明了
- 遵循项目现有的代码风格

## 常见问题

### 安装失败怎么办？

1. 检查安装日志，查看具体错误信息
2. 确保系统满足安装要求
3. 确保网络连接正常

### 配置文件不生效怎么办？

1. 检查配置文件是否正确安装
2. 检查配置文件权限是否正确
3. 重新加载配置文件
```shell
source ~/.bashrc
```

4. 重启终端或系统

### 如何添加新的配置文件？

1. 将配置文件放在对应的目录中
2. 更新安装脚本，添加新配置文件的安装逻辑
3. 测试安装过程
4. 提交修改

## 支持的系统

- **Arch Linux**
- **Ubuntu**
- **Debian**
- **CentOS**

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/crochee/dotfiles
- 邮箱: your.email@example.com

## 更新日志

### v1.0.0 (2024-10-10)
- 初始版本发布
- 支持多种开发语言
- 包含基础配置文件
- 实现自动化安装

---

**欢迎使用 dotfiles！** 🎉

如果你觉得这个项目对你有帮助，请给个 ⭐ 支持一下！
