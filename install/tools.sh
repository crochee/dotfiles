#!/usr/bin/env bash
# CLI 工具的安装与更新
#   install/tools.sh          安装缺失的工具
#   install/tools.sh update   更新已装的工具
#
# 策略：mise 是主通道 —— 凡 mise 能管理的 CLI 一律进 config/mise/config.toml，
# 由 mise install / mise upgrade 统一装升（runtimes、starship、fd、rg、bat、
# neovim、zoxide、kind、uv、oh-my-pi…）。
# mise 管不了才单独管：
#   - mise 自身：bootstrap（pacman/brew/curl）后 mise self update；
#   - docker：系统守护进程，随系统包管理器走；
#   - fish：多源安装（apt/pacman/brew），无 sudo 时用 fish-portable fallback；
#   - fisher：fish 插件管理框架（curl fisher.fish 单文件）；
#   - fish 插件：fish_plugins 列出插件名 + fisher install 从 GitHub 增量拉。
set -euo pipefail

say() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
OS=$(uname)

# P0：starship/zoxide init 产物静态缓存刷新（system/tools.fish 直接 source 缓存，
# 免每 shell spawn）。mise 升级版本后调用，保证缓存与最新 init 产物同步；
# rc 侧在缓存缺失时也会自愈生成一次。
regen_init_caches() {
    local cdir spec bin
    cdir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
    mkdir -p "$cdir" 2>/dev/null || return 0
    for spec in starship zoxide; do
        bin=$(command -v "$spec" 2>/dev/null) || continue
        if [ "$spec" = starship ]; then
            "$bin" init fish --print-full-init > "$cdir/starship-init.fish" 2>/dev/null \
                || true
        else
            "$bin" init fish --cmd cd > "$cdir/zoxide-init.fish" 2>/dev/null \
                || true
        fi
    done
}

# 系统包管理器通道：只装 mise 管不了的（守护进程类）
pkg() {
    local cmd=$1 brew=$2 pac=$3 apt=$4
    have "$cmd" && { say "$cmd 已安装"; return 0; }
    say "安装 $cmd"
    if [[ $OS == Darwin ]] && have brew; then
        brew install "$brew"
    elif have pacman; then
        sudo pacman -Syu --noconfirm "$pac"
    elif have apt && [[ -n $apt ]]; then
        sudo apt install -y "$apt"
    else
        say "跳过 $cmd：无可用安装通道"
    fi
}

# 按当前 OS 分发到 brew / pacman / apt：install_tools、install_fish、update_tools 共用
# - Darwin → brew
# - Arch Linux → pacman
# - 其他 Linux → apt
# 不处理「已装跳过」与「无 sudo fallback」（调用方负责）
_pkg_install() {
    if [[ $OS == Darwin ]] && have brew; then
        brew install "$@"
    elif have pacman; then
        sudo pacman -Syu --noconfirm "$@"
    elif have apt; then
        sudo apt install -y "$@"
    else
        return 1
    fi
}

_pkg_upgrade() {
    if [[ $OS == Darwin ]] && have brew; then
        brew upgrade
    elif have pacman; then
        sudo pacman -Syu --noconfirm
    elif have apt; then
        sudo apt update && sudo apt upgrade -y
    else
        return 1
    fi
}

# fish 多源安装
# 1) 系统包管理器（apt/pacman/brew）— 优先，要求 sudo
# 2) fish-portable fallback：从 fish-shell 官方 release 下载 portable AppImage
#    （无 sudo / 包管理器不可用 / 系统装不上时）
install_fish() {
    if have fish; then
        say "fish 已安装: $(command -v fish) ($(fish --version 2>&1))"
        return 0
    fi
    say "安装 fish"
    if ! _pkg_install fish; then
        # fallback：portable AppImage
        install_fish_portable
    fi
}

# fish portable（Arch-WSL / 无 sudo 路径）
# 从 fish-shell/fish-shell GitHub release 下载 Linux x86_64 AppImage
install_fish_portable() {
    local _fp="$HOME/.local/share/fish-portable"
    if [ -x "$_fp/fish.AppImage" ]; then
        say "fish portable 已存在"
        return 0
    fi
    say "下载 fish portable AppImage"
    local frel furl
    frel=$(curl -fsSL https://api.github.com/repos/fish-shell/fish-shell/releases/latest \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
    [ -z "$frel" ] && { say "无法解析 fish 最新版本"; return 1; }
    furl="https://github.com/fish-shell/fish-shell/releases/download/${frel}/fish-${frel#v}-x86_64.AppImage"
    mkdir -p "$_fp"
    curl -fsSL -o "$_fp/fish.AppImage" "$furl"
    chmod +x "$_fp/fish.AppImage"
    # AppImage 需 FUSE；如不行，用 --appimage-extract 拿 squashfs-root
    if "$_fp/fish.AppImage" --version 2>/dev/null; then
        :
    else
        say "AppImage 不可执行（无 FUSE？），改用 archive 兜底"
        rm -f "$_fp/fish.AppImage"
        return 1
    fi
}

# fisher：fish 插件管理框架
# 从 jorgebucaran/fisher GitHub 仓库直接 curl fisher.fish 单文件（不依赖 git submodule）
# fisher 框架本身只是一个 200 行的 fish 文件，不值得作为 submodule
install_fisher() {
    local fish_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    if [ -f "$fish_cfg/functions/fisher.fish" ]; then
        say "fisher 已安装: $fish_cfg/functions/fisher.fish"
        return 0
    fi
    say "安装 fisher"
    command -v fish >/dev/null 2>&1 || { say "需要 fish（先 install_fish）"; return 1; }
    command -v curl >/dev/null 2>&1 || { say "需要 curl"; return 1; }
    mkdir -p "$fish_cfg/functions"
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
        -o "$fish_cfg/functions/fisher.fish" \
        || { say "下载 fisher.fish 失败（网络？）"; return 1; }
    say "fisher 已下载；首次启动 fish 后会自动从 fish_plugins 装插件"
}

# fish 插件：fisher 4.x 用 fish_plugins（每行一个 owner/repo）作为插件清单
# fisher install <pkg1> <pkg2> ... 必须传包名（不接受无参调用）
# 不再作为 git submodule（避免 clone 大仓库时网络问题）
# fish_plugins 在仓库内 config/fish/fish_plugins，install.sh 软链到 ~/.config/fish/fish_plugins
install_fish_plugins() {
    local fish_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    local repo="${DOTFILES_DIR:-$HOME/.dotfiles}"
    [ -d "$repo" ] || { say "DOTFILES_DIR 不存在，跳过插件"; return 0; }
    [ -f "$repo/config/fish/fish_plugins" ] || { say "$repo 无 config/fish/fish_plugins，跳过"; return 0; }
    if [ ! -f "$fish_cfg/functions/fisher.fish" ]; then
        say "fisher 未装（先 install_fisher）"
        return 0
    fi
    command -v fish >/dev/null 2>&1 || { say "需要 fish"; return 0; }
    # 把 fish_plugins 的非空非注释行展开为 fisher install 参数
    local pkgs
    pkgs=$(grep -vE '^\s*($|#)' "$repo/config/fish/fish_plugins" | tr '\n' ' ')
    [ -n "$pkgs" ] || { say "fish_plugins 无有效插件，跳过"; return 0; }
    say "fisher install（按 fish_plugins 装/升级）: $pkgs"
    # shellcheck disable=SC2086
    fish -c "fisher install $pkgs" 2>&1 | head -30 \
        || say "fisher install 失败（网络？稍后手动跑：fish -c 'fisher install $pkgs'）"
}

install_tools() {
    # mise：先 bootstrap，其余 CLI 全靠它
    if ! have mise; then
        say "安装 mise"
        if ! _pkg_install mise; then
            curl -fsSL https://mise.run | sh
        fi
        export PATH="$HOME/.local/bin:$PATH"
    fi
    export PATH="$HOME/.local/share/mise/shims:$PATH"

    if [ ! -f "$HOME/.config/mise/config.toml" ]; then
        say "提示：~/.config/mise/config.toml 不存在，先运行 install/install.sh config"
    fi

    # 主通道：按 config/mise/config.toml 装齐全部受管 CLI
    say "mise install（工具清单见 config/mise/config.toml）"
    mise install
    # P0：升级后刷新 starship/zoxide init 静态缓存
    regen_init_caches

    # fish：多源安装
    install_fish

    # fisher：fish 插件管理框架
    install_fisher

    # fish 插件（通过 fish_plugins + fisher install 增量装）
    install_fish_plugins

    # docker：守护进程必须随系统走，mise 不接管
    pkg docker docker docker docker

    # GOPROXY 一次性配置（从 shell 启动路径移过来的幂等设置）
    if have go && [[ $(go env GOPROXY) == direct ]]; then
        go env -w GOPROXY=https://goproxy.io,https://goproxy.cn,https://proxy.golang.org,direct
    fi
}

update_tools() {
    # mise：自身 + 全部受管工具
    if have mise; then
        mise self update || true
        mise upgrade -y || true
        # P0：版本升级后刷新 starship/zoxide init 静态缓存
        regen_init_caches
    fi

    # 系统层升级（docker 守护进程与 OS 包）
    _pkg_upgrade || say "无系统包管理器，跳过 OS 升级"

    # fisher：自更新（按 fish_plugins 清单同步所有插件，无须再调 install_fish_plugins）
    if have fish; then
        fish -c "fisher update" 2>/dev/null || true
    fi
}

case "${1:-install}" in
    install | "") install_tools ;;
    update | -u | --update) update_tools ;;
    *)
        echo "用法: $0 [install|update]" >&2
        exit 1
        ;;
esac
