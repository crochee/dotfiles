# ~/.config/fish/config.fish —— fish 唯一入口
#
# 源仓库：~/.dotfiles/config/fish/config.fish，由 install/install.sh 软链到
# $XDG_CONFIG_HOME/fish/config.fish。fish 启动时自动 source。
#
# 加载顺序：
#   0. 基础环境（DOTFILES_DIR / WORKSPACE / XDG_*）
#   1. system/env.fish            —— 环境变量
#   2. system/alias.fish          —— 别名与函数
#   3. system/tools.fish          —— fish 端 init（mise/starship/zoxide）

# 非交互 shell（脚本 sub-shell）直接返回
status is-interactive || exit 0

# 关闭启动欢迎语（"Welcome to fish..."）：把 fish_greeting 置空，
# fish 内置 fish_greeting() 在 test -n "$fish_greeting" 处直接 return。
set -g fish_greeting


# -------------------- 0. 基础环境 --------------------
set -gx DOTFILES_DIR "$HOME/.dotfiles"
set -gx WORKSPACE "$HOME/workspace"
test -z "$XDG_CONFIG_HOME"; and set -gx XDG_CONFIG_HOME "$HOME/.config"
test -z "$XDG_CACHE_HOME"; and set -gx XDG_CACHE_HOME "$HOME/.cache"
test -z "$XDG_DATA_HOME"; and set -gx XDG_DATA_HOME "$HOME/.local/share"

mkdir -p "$WORKSPACE" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"

# macOS Homebrew
test -d /opt/homebrew/bin; and fish_add_path --prepend /opt/homebrew/bin

# PATH 前置（mise shims / 个人 bin / cargo bin —— 与 tools.fish 的 mise activate
# 互补；activate 内部还会重排 PATH，这里放的是用户级固定入口）
fish_add_path --prepend "$HOME/.local/share/mise/shims"
fish_add_path --prepend "$HOME/.local/share/nvim/mason/bin"
fish_add_path --prepend "$HOME/.local/bin"
fish_add_path --prepend "$DOTFILES_DIR/bin"
fish_add_path --prepend "$HOME/.cargo/bin"

# -------------------- 1. system/env.fish --------------------
test -r "$DOTFILES_DIR/system/env.fish"; and source "$DOTFILES_DIR/system/env.fish"

# -------------------- 2. system/alias.fish --------------------
test -r "$DOTFILES_DIR/system/alias.fish"; and source "$DOTFILES_DIR/system/alias.fish"

# -------------------- 3. system/tools.fish --------------------
test -r "$DOTFILES_DIR/system/tools.fish"; and source "$DOTFILES_DIR/system/tools.fish"
