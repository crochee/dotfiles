#!/usr/bin/env bash
# dotfiles 安装：克隆仓库，把 dotfiles/ 与 config/ 以符号链接装进 $HOME
# 用法：install.sh [home|config|fish|all]   （默认 all）
set -euo pipefail

readonly SOURCE="https://github.com/crochee/dotfiles.git"
readonly TARGET="$HOME/.dotfiles"
# backup 路径优先 $XDG_DATA_HOME/dotfiles-backup；否则 $HOME/dotfiles-backup_*
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles" 2>/dev/null
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR" 2>/dev/null || BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

info() { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
用法: install.sh [home|config|fish|all]
  home    安装 dotfiles/ 到 $HOME（.bashrc/.gitconfig/.inputrc/...）
  config  安装 config/ 到 $HOME/.config
  fish    安装 config/fish/ -> ~/.config/fish（config.fish + conf.d/ + plugins 软链）
  all     全部安装（默认）
EOF
    exit 0
}

# 备份已存在的目标后创建符号链接；已指向本仓库的跳过
link() {
    local src=$1 dst=$2
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return 0
    fi
    if [ -e "$src" ]; then
        : # source OK
    else
        # 源缺失（已删除的废弃文件如 .bashrc/.zshrc）：不创建死链，
        # 顺手清理 $HOME 下残留的死链目标。
        if [ -L "$dst" ] && [ ! -e "$dst" ]; then
            rm -f "$dst" || warn "清理死链失败：$dst（请手动 rm）"
            info "已清理死链 $dst（源 $src 不存在）"
        else
            warn "跳过链接：源不存在 $src"
        fi
        return 0
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
        warn "已备份 $dst -> $BACKUP_DIR/"
    fi
    ln -sfn "$src" "$dst"
}

prepare_repo() {
    if [ -d "$TARGET/.git" ]; then
        info "仓库已存在：$TARGET"
        return 0
    fi
    command -v git >/dev/null 2>&1 || die "需要 git"
    info "克隆 $SOURCE"
    mkdir -p "$TARGET"
    git clone --depth 1 "$SOURCE" "$TARGET" || die "克隆失败，可手动克隆到 $TARGET 后重跑"
}

# dotfiles/* + fish：home 与 all 共用的核心安装步骤
install_core() {
    install_home
    install_fish
}

# 注：废弃文件若已存在为指向仓库旧位置的死链，link() 会顺手清理（src 不再存在）
install_home() {
    info "安装 dotfiles/ -> $HOME"
    local src name
    shopt -s dotglob nullglob
    for src in "$TARGET"/dotfiles/*; do
        name=$(basename "$src")
        link "$src" "$HOME/$name"
    done
    shopt -u dotglob
}

# config/fish/* -> ~/.config/fish/（集中管理）
# - config.fish   → ~/.config/fish/config.fish（入口）
# - conf.d/        → ~/.config/fish/conf.d/（fish 自动 source 全部 .fish）
# - functions/     → ~/.config/fish/functions/（fish 函数定义）
# - fishfile       → ~/.config/fish/fishfile（fisher 插件清单，fisher 4.x 自动读）
# 不再软链 fish/plugins/* —— 插件代码不放仓库（避免网络问题），由 fisher install 增量从 GitHub 拉
#
# 为什么单独成 install_fish() 而不是 install_config() 整链：
# - install_config() 会把 config/fish/ 整目录链到 ~/.config/fish/，
#   接管 fisher 运行时产物（functions/fisher.fish、completions/、用户 conf.d/），
#   与「按文件级链接 + 允许运行时自管目录」的语义冲突
# - 因此 install_fish() 只链文件，保留目录所有权给 fish 运行时
install_fish() {
    info "安装 config/fish/ -> ~/.config/fish"
    [ -d "$TARGET/config/fish" ] || { warn "config/fish/ 目录不存在，跳过"; return 0; }
    local fdot="$TARGET/config/fish"
    local fish_cfg="$HOME/.config/fish"
    mkdir -p "$fish_cfg"

    # config.fish 是入口
    [ -f "$fdot/config.fish" ] && link "$fdot/config.fish" "$fish_cfg/config.fish"

    # conf.d/ 拆分模块（fish 自动 source 全部） + functions/（fish 函数定义目录）
    _link_fish_dir "$fdot/conf.d"    "$fish_cfg/conf.d"
    _link_fish_dir "$fdot/functions" "$fish_cfg/functions"

    # fish_plugins（fisher 4.x 插件清单，每行一个 owner/repo）—— fisher 自动维护
    [ -f "$fdot/fish_plugins" ] && link "$fdot/fish_plugins" "$fish_cfg/fish_plugins"

    # 旧 plugins/ 软链（如果还在）：移除、保留已装插件
    # - 死链（指向已删的 fish/plugins/*）直接 rm
    # - 仍指向新位置的（已迁过来）保留
    for old_plugin in fisher autopair.fish fzf.fish; do
        local p="$HOME/.local/share/fish/plugins/$old_plugin"
        if [ -L "$p" ] && [ ! -e "$p" ]; then
            info "清理死链 plugins/$old_plugin（指向已删目录；改用 fish_plugins + fisher install）"
            rm -f "$p" 2>/dev/null || warn "unlink failed: $p（请手动 rm）"
        fi
    done
}

# 把 src_dir/*.fish 软链到 dst_dir/（同名）。源目录不存在则跳过。
_link_fish_dir() {
    local src_dir=$1 dst_dir=$2
    [ -d "$src_dir" ] || return 0
    mkdir -p "$dst_dir"
    local f
    for f in "$src_dir"/*.fish; do
        [ -f "$f" ] || continue
        link "$f" "$dst_dir/$(basename "$f")"
    done
}

# 「运行时目录」通用链接：解除旧链接占位 → mkdir → 逐文件 link。
# 用于 fish-ai 等运行时工具：它们的 config/ 不应整体被覆盖（state/日志会丢）。
_link_runtime_dir() {
    local src=$1 dst=$2
    [ -L "$dst" ] && rm "$dst"
    mkdir -p "$dst"
    local f
    for f in "$src"/*; do
        link "$f" "$dst/$(basename "$f")"
    done
}

# config/* -> $HOME/.config。
# 注：config/fish 与 config/fish-ai 不在此处整链——
#   fish    由 install_fish() 文件级接管（fisher 运行时目录所有权）
#   fish-ai 由 _link_runtime_dir() 文件级接管（运行时 state/日志）
install_config() {
    info "安装 config/ -> $HOME/.config"
    mkdir -p "$HOME/.config"
    shopt -s nullglob
    local src
    for src in "$TARGET"/config/*; do
        name=$(basename "$src")
        case $name in
            starship) link "$src/starship.toml" "$HOME/.config/starship.toml" ;;
            cargo)    mkdir -p "$HOME/.cargo" && link "$src/config.toml" "$HOME/.cargo/config.toml" ;;
            fish|fish-ai) ;; # 接管位置见 install_fish() / _link_runtime_dir()，详见函数头注释
            *)        link "$src" "$HOME/.config/$name" ;;
        esac
    done
    shopt -u nullglob
}

# 自动 chsh 到 fish：仅 all / fish 子命令触发，home/config 子命令不触碰
# 行为：检测 fish 已装 + 在 /etc/shells → 询问用户确认 → 备份当前 shell → chsh
maybe_chsh_to_fish() {
    local fish_path
    # fish 探测优先级：/usr/bin/fish → command -v → fish-portable 兜底
    # 优先 /usr/bin/fish：避免 /usr/sbin/fish（hardlink，chsh 某些发行版拒绝）
    if [ -x /usr/bin/fish ]; then
        fish_path=/usr/bin/fish
    else
        fish_path="$(command -v fish 2>/dev/null || true)"
    fi
    if [ -z "$fish_path" ] && [ -x "$HOME/.local/share/fish-portable/fish.AppImage" ]; then
        fish_path="$HOME/.local/share/fish-portable/fish.AppImage"
    fi
    if [ -z "$fish_path" ]; then
        info "未检测到 fish，跳过 chsh（运行 install/tools.sh install 装 fish 后重跑）"
        return 0
    fi
    # 不在 /etc/shells 里 → chsh 会失败，先 add
    if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
        info "$fish_path 不在 /etc/shells，尝试添加（需要 sudo）"
        if command -v sudo >/dev/null 2>&1; then
            if ! echo "$fish_path" | sudo -n tee -a /etc/shells >/dev/null 2>&1; then
                warn "添加 /etc/shells 失败（需要 sudo 密码或无 sudo）"
                info "手动：echo $fish_path | sudo tee -a /etc/shells"
                install_fish_fallback_bash_profile
                return 0
            fi
        else
            warn "无 sudo 且 $fish_path 不在 /etc/shells"
            install_fish_fallback_bash_profile
            return 0
        fi
    fi
    # 已是 fish
    if [ "${SHELL:-}" = "$fish_path" ]; then
        info "当前 shell 已是 fish，无需 chsh"
        return 0
    fi
    # 询问
    printf '%s' "切换默认 shell 到 $fish_path？[y/N] "
    local ans
    read -r ans
    case "${ans:-N}" in
        y|Y|yes|YES) ;;
        *) info "已跳过 chsh（手动：chsh -s $fish_path）"; return 0 ;;
    esac
    # 备份：把当前 shell 写到 ~/dotfiles-backup_<时间>/SHELL
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    echo "${SHELL:-unknown}" > "$BACKUP_DIR/SHELL.bak" 2>/dev/null
    info "当前 shell 已备份到 $BACKUP_DIR/SHELL.bak"
    if chsh -s "$fish_path" 2>/dev/null; then
        info "chsh 成功；新会话生效（exec \$SHELL 或重开终端）"
    else
        warn "chsh 失败（手动执行：chsh -s $fish_path）"
        install_fish_fallback_bash_profile
    fi
}

# chsh 无权限时的回退：写 ~/.bash_profile 让登录 bash 直接 exec fish
# 仅在当前 shell 是 bash 时启用（避免破坏其它 shell 用户）
install_fish_fallback_bash_profile() {
    case "${SHELL:-}" in
        */bash)
            _bp="$HOME/.bash_profile"
            if [ -f "$_bp" ] && grep -qE 'exec[[:space:]]+.*fish' "$_bp" 2>/dev/null; then
                info "$_bp 已有 fish exec 行为，跳过"
                return 0
            fi
            printf '\n# dotfiles: 自动切到 fish（chsh 在此环境无权限；登录 bash 直接 exec fish）\n# 先 export SHELL（chsh 失败时 /etc/passwd 仍是 bash；脚本会判错）\n[ -x "$HOME/.local/share/fish-portable/fish.AppImage" ] && export SHELL="$HOME/.local/share/fish-portable/fish.AppImage" && exec "$HOME/.local/share/fish-portable/fish.AppImage"\n[ -x /usr/bin/fish ] && export SHELL=/usr/bin/fish && exec /usr/bin/fish\n' >> "$_bp" 2>/dev/null \
                && info "已写入 $_bp（登录 bash 自动 exec fish；恢复：删 _bp 末尾的 exec 行）" \
                || warn "写 $_bp 失败，可手动追加上面 exec 行"
            unset _bp
            ;;
    esac
}

main() {
    local what=${1:-all}
    case "$what" in
        -h | --help | help) usage ;;
    esac

    prepare_repo

    case "$what" in
        home)   install_core ;;
        config) install_config ;;
        all)    install_core; install_config; maybe_chsh_to_fish ;;
        fish)   install_fish; maybe_chsh_to_fish ;;
        *) die "未知参数：$what（可用：home | config | fish | all）" ;;
    esac

    info "完成。执行 exec \$SHELL 或重开终端生效。"
}

main "$@"
