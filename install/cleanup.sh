#!/usr/bin/env bash
# 缓存与日志清理
#   - mise 下载缓存（~/.local/share/mise/cache）
#   - docker 无用数据（停容器、dangling image、未用 network/volume）
set -euo pipefail

say() { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# 清理 mise 下载缓存
if have mise; then
    say "清理 mise 缓存..."
    mise cache clear
fi

# 清理 docker 无用数据
if have docker; then
    say "清理 docker 无用数据..."
    docker system prune -f
fi

say "清理完成！"