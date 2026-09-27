#!/bin/sh
# Bootstrap prerequisite check. Hard-fail if git/curl missing.
set -u

say() { printf '\n==> %s\n' "$*"; }

_missing=0
for _cmd in git curl; do
    if command -v "$_cmd" >/dev/null 2>&1; then
        say "found $_cmd: $(command -v "$_cmd")"
    else
        say "MISSING: $_cmd"
        _missing=$((_missing + 1))
    fi
done

if [ "$_missing" -gt 0 ]; then
    cat >&2 <<'EOF'

bootstrap 前置缺失: git 和 curl 必须先由你用平台 PM 装好.
例:
  Arch:          sudo pacman -S git curl
  Debian/Ubuntu: sudo apt install git curl
  Fedora/RHEL:   sudo dnf install git curl
  macOS:         brew install git          (curl 系统自带)

装好后请重跑: bash ~/.dotfiles/install/install.sh
EOF
    exit 1
fi

exit 0