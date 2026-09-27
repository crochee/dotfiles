#!/usr/bin/env bash
# Manual cache + duplicate cleanup. Steps: cache (mise) | docker (system prune) | dups (PM<->mise).
# `docker system prune -f` deletes kind node containers — this is not bootstrap.
set -uo pipefail

say() { printf '\033[0;34m==>\033[0m %s\n' "$*"; }

DRY_RUN=0
ONLY=all
for _arg in "$@"; do
    case "$_arg" in
        -n | --dry-run) DRY_RUN=1 ;;
        --only=cache | --only=docker | --only=dups) ONLY=${_arg#--only=} ;;
        *)
            say "未知参数: $_arg (可用: --dry-run / --only=cache|docker|dups)"
            exit 2
            ;;
    esac
done
[ "$DRY_RUN" = 1 ] && say "dry-run: 只打印, 不执行"
[ "$ONLY" != all ] && say "只跑步骤: $ONLY"
_step() { [ "$ONLY" = all ] || [ "$ONLY" = "$1" ]; }

run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '    [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

if _step cache; then
    say "清理 mise 下载缓存..."
    run mise cache clear || say "  mise cache clear failed (mise not on PATH?)"
fi

if _step docker; then
    say "清理 docker 无用数据 (停止的容器 / 未用网络 / dangling 镜像 / 构建缓存)..."
    run docker system prune -f || say "  docker system prune failed (docker not on PATH?)"
fi

# mise [tools] is the single source — remove PM duplicates that overlap with a mise shim.
# Table: <binary>:<pkg>[:<shim>] — third segment only when PM name ≠ shim name.
# Excluded: bootstrap-pre (git/curl/chezmoi/mise) + system python (gdb/vim hard-dep).
# PM-specific: brew=kubernetes-cli, dpkg=docker.io. PM package orphan cleanup is the user's job.
if _step dups; then
    say "移除非 mise 渠道的同名 CLI 副本 (brew 不需 sudo; 其他 PM 需 sudo)..."
    _shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
    _mise_bin() { [ -x "$_shims/$1" ]; }
    _removed=0

    _common="zoxide:zoxide rg:ripgrep nvim:neovim yq:yq bat:bat"

    _purge() { # _purge <pm> <probe> <sudo?> <rm> <args> <pairs...>
        local _pm=$1 _probe=$2 _sudo=$3 _rm=$4 _args=$5 _pair _bin _rest _pkg _shim
        shift 5
        command -v "$_pm" >/dev/null 2>&1 || return 0
        for _pair; do
            _bin=${_pair%%:*}
            _rest=${_pair#*:}
            _pkg=${_rest%%:*}
            _shim=${_rest#*:}
            [ "$_shim" = "$_rest" ] && _shim=$_bin
            _mise_bin "$_shim" || continue
            # shellcheck disable=SC2086  # intentional word-split: $_rm and $_args are flag lists.
            $_probe "$_pkg" >/dev/null 2>&1 || continue
            say "  $_rm $_args $_pkg (mise 已提供 $_bin)"
            if [ "$_sudo" = sudo ]; then
                # shellcheck disable=SC2086
                run sudo $_rm $_args "$_pkg" || say "    $_rm $_args $_pkg failed"
            else
                # shellcheck disable=SC2086
                run $_rm $_args "$_pkg" || say "    $_rm $_args $_pkg failed"
            fi
            _removed=$((_removed + 1))
        done
    }

    # shellcheck disable=SC2086  # intentional word-split: $_common is a list of binary:pkg pairs.
    _purge pacman 'pacman -Qq' sudo 'pacman -R' --noconfirm \
        $_common kubectl:kubectl delta:git-delta mcfly:mcfly \
        lazygit:lazygit kind:kind starship:starship docker:docker \
        7zz:unzip 7zz:7zip 7zz:p7zip \
        docker-buildx:docker-buildx:docker-cli-plugin-docker-buildx

    # shellcheck disable=SC2086
    _purge dpkg 'dpkg -s' sudo 'apt purge' -y \
        $_common 7zz:unzip docker:docker.io

    # shellcheck disable=SC2086
    _purge rpm 'rpm -q' sudo 'dnf remove' -y \
        $_common 7zz:unzip docker:docker

    # shellcheck disable=SC2086
    _purge brew 'brew list --formula' nosudo 'brew uninstall' '' \
        $_common kubectl:kubernetes-cli delta:git-delta mcfly:mcfly \
        lazygit:lazygit kind:kind starship:starship docker:docker \
        7zz:unzip docker-buildx:docker-buildx:docker-cli-plugin-docker-buildx

    unset -f _purge _mise_bin
    unset _shims _common

    [ "${_removed:-0}" = 0 ] && say "  未发现重复副本"
    unset _removed
fi

say "清理完成!"