# dotfiles

个人开发环境配置，符号链接进 `$HOME`，git 管理，一键安装。

## 布局

```
dotfiles/                  # 装进 $HOME 的文件（.gitconfig/.inputrc/.myclirc）
system/                    # fish 端共用配置（由 config.fish source）
  ├── .env.local           #   密钥（gitignored）
  └── env.fish / alias.fish / tools.fish
config/                    # 装进 ~/.config 的应用配置
  ├── cargo/               #   -> ~/.cargo/config.toml（镜像源）
  ├── mise/                #   CLI 工具清单（由 mise install 统一装升）
  ├── nvim/  starship/  uv/  wezterm/
  ├── fish/                #   文件级软链到 ~/.config/fish/（install_fish 文件级接管；fisher 运行时目录不能整链）
  │   ├── config.fish      #     → ~/.config/fish/config.fish（fish 入口）
  │   └── fish_plugins     #     → ~/.config/fish/fish_plugins（fisher 4.x 插件清单）
  └── fish-ai/             #   文件级链接进 ~/.config/fish-ai/（fish 端 AI 插件配置）

install/
  ├── install.sh           # 符号链接安装器（home | config | fish | all）
  ├── tools.sh             # CLI 工具安装/更新（install | update）
  └── cleanup.sh           # mise/docker 缓存清理
bin/                       # 个人脚本（install-assets、checkin.sh、gitlogself.sh、rsx）
k8s/                       # kind 集群与各服务 docker 部署脚本、WSL/docker 主机配置
skills/  agents/           # Claude Code 技能与代理
docs/                      # 参考笔记
.claude-plugin/            # Claude Code 插件清单
CLAUDE.md                  # Claude Code 行为指南
```

## 安装

```bash
# 一键（克隆 + 全量安装）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/crochee/dotfiles/master/install/install.sh)"

# 或手动
git clone https://github.com/crochee/dotfiles.git ~/.dotfiles
~/.dotfiles/install/install.sh            # home + config + fish + chsh 询问
~/.dotfiles/install/install.sh home       # 仅 $HOME 文件
~/.dotfiles/install/install.sh config     # 仅 ~/.config
~/.dotfiles/install/install.sh fish       # 仅 fish（含 chsh 询问）
```

- 被替换的原文件备份到 `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/backup-<时间戳>/`
- 重复执行是幂等的：已指向本仓库的链接直接跳过
- 工具安装：`install/tools.sh`；升级：`install/tools.sh update`

## chsh 切到 fish

`install/install.sh fish`（或 `all`）会自动尝试 chsh：

1. 探测 fish 路径（**优先 `/usr/bin/fish`**；避免 `/usr/sbin/fish`，那是 `/usr/bin/fish` 的 hardlink，某些发行版的 chsh 拒绝 hardlink）
2. 检查 `/etc/shells` 包含此路径；不在则用 `sudo tee -a /etc/shells` 添加
3. 询问用户确认
4. 备份当前 shell 到 `${XDG_DATA_HOME}/dotfiles/backup-*/SHELL.bak`
5. `chsh -s /usr/bin/fish`（或 fish-portable 路径）

**手动 chsh**（如果 install.sh 自动 chsh 失败）：

```bash
sudo chsh -s /usr/bin/fish crochee
# 然后：重开终端 或 exec fish
```

**chsh 失败的回退路径**：install.sh 会在 `~/.bash_profile` 末尾追加 `exec /usr/bin/fish`（仅当当前 shell 是 bash 时启用）—— 登录 bash 时自动 exec fish，无需 chsh。

## Shell 结构

**默认 shell：fish**（apt/pacman/brew 多源安装，无 sudo 时走 fish-portable fallback）。
安装和默认 shell 切换由 `install/install.sh fish` 一并完成（含自动 chsh 询问）。

- `config/fish/config.fish` → 软链到 `$HOME/.config/fish/config.fish`（fish 唯一入口）
  - `system/{env.fish, alias.fish, tools.fish}` 共用配置
  - `config/fish/conf.d/*.fish` 拆分模块（fish 自动 source）
  - `config/fish/fish_plugins` 插件清单（fisher 4.x 自动读；插件代码不存仓库，避免网络问题）

**插件框架：fisher**（[jorgebucaran/fisher](https://github.com/jorgebucaran/fisher)）：

- 仓库**不存**插件源码（避免 submodule 在弱网环境 clone 失败）
- 插件清单在 [`config/fish/fish_plugins`](file:///home/crochee/.dotfiles/config/fish/fish_plugins)，每行一个 `owner/repo`：
  - `jorgebucaran/autopair.fish` —— 自动补全括号/引号
  - `PatrickF1/fzf.fish` —— 用 fzf 替换补全/历史/变量选择（Ctrl-R/Ctrl-T/Alt-C）
  - `Realiserad/fish-ai` —— fish 端 AI 助手：注释→命令、命令修复、自动补全（Ctrl+P / Ctrl+Space），模型走 DeepSeek，密钥复用 `system/.env.local` 的 `OPENAI_API_KEY`，配置见 `config/fish-ai/fish-ai.ini`
- 装：`fish -c 'fisher install <pkg...>'`（install/tools.sh 按 fish_plugins 自动展开）
- 升级：`fish -c 'fisher update'`（一次性更新全部已装插件）

**fish 内建 intelligence**（开箱即用，无需插件）：

- `fish_command_not_found` —— 拼错命令建议（带反白 + 路径提示）
- autosuggestions —— 逐键 ghost 建议（基于 history / completion 双源；右键接受）
- syntax highlighting —— 实时命令着色（红=错绿=对）
- history pager —— `fish_history` pager（`Alt-↑/↓`）
- 智能补全 —— 基于 man page 自动解析补全

## 工具

CLI 一律由 mise 管理（runtimes 与 starship/fd/rg/bat/neovim/zoxide/kind/uv/
lazygit/oh-my-pi…，清单见 `config/mise/config.toml`）。例外：docker
守护进程随系统包管理器；fish 由 `install/tools.sh` 多源安装。

starship 提示符（**fish 友好**）；zoxide 接管 cd；wezterm 终端（**default_prog = fish**）；neovim（LSP/DAP/lazy.nvim）。

```bash
mise use -g <tool>@latest   # 新增工具（写进 config/mise/config.toml）
mise install                # 按 config 装齐（install/tools.sh 的主通道）
mise upgrade -y             # 升级 mise 管理的工具
```

## Claude Code 插件
把技能/代理软链进其他编辑器（仓库是唯一源，改动即时生效）：

```bash
install-assets skills claude     # 软链到 ~/.claude/skills
install-assets agents claude -f  # 清空后全量链接 agents
install-assets skills claude -d  # 只删除
```

## 日常维护

```bash
dot                        # 进仓库（别名）
git pull && ./install/install.sh fish   # 拉取后重跑 fish 软链 + chsh 询问
./install/tools.sh update          # 升级 CLI 工具
./install/cleanup.sh               # 清 mise/docker 缓存
```
