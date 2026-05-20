# dotfiles

个人开发环境配置文件集合，用于快速搭建和管理开发环境。

## 功能介绍

### 核心功能
- **多 Shell 支持**：Bash、Zsh 配置
- **现代化终端**：Wezterm 终端配置、Starship 提示符
- **高效编辑器**：Neovim 完整配置（LSP、DAP、40+ 插件）
- **工具版本管理**：mise 一站式管理 Go、Rust、Node.js、Python 等
- **Python 工具**：uv 快速的 Python 包和项目管理
- **Kubernetes 配置**：k8scnf 目录包含各种 Kubernetes 部署配置
- **命令增强**：atuin 命令历史、zoxide 目录跳转、fzf 模糊搜索
- **模块化设计**：按功能和应用程序分类管理配置文件
- **自动化安装**：一键安装和更新配置，符号链接方式便于版本控制

### 包含的配置

#### Shell 环境
- **Bash**：`.bashrc` 及相关配置
- **Zsh**：`.zshrc` 及相关配置（支持 oh-my-zsh）
- **插件**：fzf、zsh-autosuggestions、zsh-syntax-highlighting

#### 编辑器与终端
- **Neovim**：完整配置，包含：
  - LSP 支持（gopls、pyright、tsserver、rust-analyzer 等）
  - DAP 支持（delve、codelldb）
  - 插件：telescope、nvim-tree、lazy.nvim、conform、noice 等
- **Wezterm**：终端模拟器配置

#### 工具版本管理 (mise)
- **Go**：版本管理
- **Rust**：版本管理
- **Node.js**：版本管理
- **Python**：版本管理

#### 开发工具配置
- **Starship**：跨平台提示符
- **Atuin**：命令历史管理
- **Zoxide**：智能目录跳转
- **FZF**：模糊搜索
- **Direnv**：环境变量管理
- **Git**：配置文件

#### 其他配置
- **Cargo**：Rust 包管理器配置
- **UV**：Python 工具管理器配置

#### Kubernetes 配置 (k8scnf)
- **Kind 集群**：本地 Kubernetes 集群配置和指南
- **数据库**：PostgreSQL、MariaDB、Redis 等部署脚本
- **消息队列**：RabbitMQ 部署
- **监控**：Prometheus 监控配置
- **AI/ML**：Ollama + Open WebUI、vLLM 部署
- **其他工具**：Vaultwarden、Memos、Shimmy 等

### Claude Code 插件

本仓库包含 Claude Code 插件结构，用于为 Claude Code 提供结构化的开发工作流。

**插件目录：** `.claude-plugin/`

**插件内容：**
- **12 个技能**：涵盖开发、测试、设计、调试等多个领域
- **6 个代理**：架构师、开发者、测试者、代码审查者、探索者、前端开发者

**安装方式：**

```bash

# 从 Git 安装
/plugin install s --from git@github.com:crochee/dotfiles.git

# 从市场安装
/plugin marketplace add crochee git@github.com:crochee/dotfiles.git
/plugin install s@crochee
```

安装后 Claude Code 会话启动时将自动加载工作流技能。

## 快速开始

### 安装前准备

确保已安装以下基础依赖：

```bash
# Arch Linux
sudo pacman -S git curl zsh stow

# Ubuntu/Debian
sudo apt update && sudo apt install git curl zsh stow

# 安装 mise（工具版本管理器）
curl https://mise.run | sh

# 安装 Starship（终端提示符）
curl -sS https://starship.rs/install.sh | sh

# 设置 zsh 为默认 shell
chsh -s /bin/zsh
```

### 安装

#### 方式一：一键安装
```shell
bash -c "$(curl -fsSl https://raw.githubusercontent.com/crochee/dotfiles/master/install/install.sh)"
```

#### 方式二：手动安装
1. 克隆仓库
```shell
git clone git@github.com:crochee/dotfiles.git ~/.dotfiles
```

2. 运行安装脚本
```shell
cd ~/.dotfiles
./install/install.sh
```

## 使用说明

### 交互式安装

运行安装脚本后，会显示交互式菜单：

```
======== INSTALL ========
1) 安装配置文件
2) 安装 dotfiles
3) 安装 dotfiles 和配置文件

请选择安装选项 [1-4]:
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

### 配置说明

#### Neovim 配置
- 配置文件位于 `config/nvim/`
- 使用 lazy.nvim 作为插件管理器
- 首次启动自动安装插件
- 依赖：git、curl、npm（用于 LSP）

#### mise 工具管理
```shell
# 激活 mise
eval "$(mise activate bash)"  # 或 zsh

# 安装工具
mise use -g go@latest
mise use -g rust@latest
mise use -g node@latest

# 查看已安装工具
mise ls
```

#### Starship 提示符
```shell
# 添加到 shell 配置
eval "$(starship init bash)"  # 或 zsh
```

## 目录结构

```
dotfiles/                      # 插件根目录
├── .claude-plugin/            # Claude Code 插件清单
├── .bashrc                    # Bash 配置
├── .zshrc                     # Zsh 配置
├── .gitignore                 # Git 忽略文件
├── CLAUDE.md                  # Claude Code 行为指南
├── config/                    # 应用程序配置
│   ├── atuin/                # Atuin 配置
│   ├── mise/                 # Mise 配置
│   ├── nvim/                 # Neovim 配置
│   ├── starship/             # Starship 配置
│   ├── uv/                   # UV Python 工具配置
│   └── wezterm/              # Wezterm 配置
├── dotfiles/                  # 用户目录配置文件
│   ├── .gitconfig            # Git 配置
│   ├── .inputrc              # Readline 配置
│   └── .myclirc              # MyCLI 配置
├── k8scnf/                    # Kubernetes 配置和部署脚本
│   ├── kind-cluster-config.yaml
│   ├── kind-cluster-guide.md
│   ├── postgres.sh
│   ├── mariadb.sh
│   ├── redis-cluster.sh
│   ├── rabbitmq.sh
│   ├── prometheus.sh
│   ├── prometheus.yml
│   ├── ollama_open-webui.sh
│   ├── vllm.sh
│   ├── vllm.Dockerfile
│   ├── vaultwarden.sh
│   ├── memos.sh
│   ├── shimmy.sh
│   ├── wsl.conf
│   ├── daemon.json
│   └── pre-commit
├── plugins/                   # 插件 subtree
│   ├── fzf/
│   ├── zsh-autosuggestions/
│   └── zsh-syntax-highlighting/
├── skills/                    # Claude Code 技能 (25个)
│   ├── agent-coach
│   ├── api-design
│   ├── brainstorming
│   ├── deep-research
│   ├── e2e-testing
│   ├── frontend-design
│   ├── git-workflow
│   ├── golang-dev
│   ├── legal-risk-auditor
│   ├── python-dev
│   ├── repo-wiki
│   ├── rust-dev
│   ├── systematic-debugging
│   ├── test-driven-development
│   ├── verification-before-completion
│   ├── writing-plans
│   └── writing-skills
├── agents/                    # Claude Code 代理 (6个)
│   ├── architect.md
│   ├── coder.md
│   ├── explore.md
│   ├── frontend.md
│   ├── reviewer.md
│   └── tester.md
├── scripts/                   # 辅助脚本
├── src/                       # 源码
├── system/                    # 系统配置
│   ├── alias.sh
│   ├── alias.zsh
│   ├── env.sh
│   ├── env.zsh
│   ├── git.sh
│   ├── path.sh
│   ├── tools.sh
│   ├── tools.zsh
│   ├── .alias
│   └── .env
└── README.md                  # 项目说明
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

安装过程中，脚本会自动备份原有的配置文件到 `~/backup_<timestamp>` 目录。

如果需要恢复配置，可以：

1. 查看备份目录
```shell
ls -la ~/backup_*
```

2. 手动恢复配置文件
```shell
cp ~/backup_2023-01-01_12-00-00/.bashrc ~/.bashrc
```

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
source ~/.bashrc    # Bash
source ~/.zshrc     # Zsh
```

4. 重启终端或系统

### Neovim 插件安装失败？

首次启动 Neovim 时，插件会自动安装。如遇问题：
1. 检查网络连接
2. 确保已安装 npm
3. 运行 `:Lazy sync` 手动同步插件

## 支持的系统

- **Arch Linux**
- **Ubuntu**
- **Debian**

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/crochee/dotfiles
