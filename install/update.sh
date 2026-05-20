#!/usr/bin/env bash

set -euo pipefail

echo "=== 开始更新工具 ==="

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

update_mise() {
  if command_exists mise; then
    echo "更新 mise..."
    mise self update 2>/dev/null || true
    echo "mise 更新完成"
  else
    echo "mise 未安装，跳过更新"
  fi
}

update_atuin() {
  if command_exists atuin; then
    echo "更新 atuin..."
    atuin self update 2>/dev/null || true
    echo "atuin 更新完成"
  else
    echo "atuin 未安装，跳过更新"
  fi
}

update_zoxide() {
  if command_exists zoxide; then
    echo "更新 zoxide..."
    zoxide self update 2>/dev/null || true
    echo "zoxide 更新完成"
  else
    echo "zoxide 未安装，跳过更新"
  fi
}

update_fzf() {
  if command_exists fzf; then
    echo "更新 fzf..."
    if [[ -d ~/.fzf ]]; then
      ~/.fzf/install --update 2>/dev/null || true
    fi
    echo "fzf 更新完成"
  else
    echo "fzf 未安装，跳过更新"
  fi
}

update_starship() {
  if command_exists starship; then
    echo "更新 starship..."
    starship self update 2>/dev/null || true
    echo "starship 更新完成"
  else
    echo "starship 未安装，跳过更新"
  fi
}

update_fd() {
  if command_exists fd; then
    echo "更新 fd..."
    if [[ "$(uname)" == "Darwin" ]]; then
      if command_exists brew; then
        brew upgrade fd 2>/dev/null || true
      fi
    elif [[ "$(uname)" == "Linux" ]]; then
      if command_exists pacman; then
        sudo pacman -Syu fd --noconfirm 2>/dev/null || true
      elif command_exists cargo; then
        cargo install fd-find 2>/dev/null || true
      fi
    fi
    echo "fd 更新完成"
  else
    echo "fd 未安装，跳过更新"
  fi
}

update_ripgrep() {
  if command_exists rg; then
    echo "更新 ripgrep..."
    if [[ "$(uname)" == "Darwin" ]]; then
      if command_exists brew; then
        brew upgrade ripgrep 2>/dev/null || true
      fi
    elif [[ "$(uname)" == "Linux" ]]; then
      if command_exists pacman; then
        sudo pacman -Syu ripgrep --noconfirm 2>/dev/null || true
      elif command_exists cargo; then
        cargo install ripgrep 2>/dev/null || true
      fi
    fi
    echo "ripgrep 更新完成"
  else
    echo "ripgrep 未安装，跳过更新"
  fi
}

update_docker() {
  if command_exists docker; then
    echo "更新 Docker..."
    if [[ "$(uname)" == "Darwin" ]]; then
      if command_exists brew; then
        brew upgrade docker 2>/dev/null || true
      fi
    elif [[ "$(uname)" == "Linux" ]]; then
      if command_exists pacman; then
        sudo pacman -Syu docker --noconfirm 2>/dev/null || true
      fi
    fi
    echo "Docker 更新完成"
  else
    echo "Docker 未安装，跳过更新"
  fi
}

update_kind() {
  if command_exists kind; then
    echo "更新 Kind..."
    if command_exists go; then
      go install sigs.k8s.io/kind@latest 2>/dev/null || true
    elif [[ "$(uname)" == "Darwin" ]]; then
      if command_exists brew; then
        brew upgrade kind 2>/dev/null || true
      fi
    elif [[ "$(uname)" == "Linux" ]]; then
      if command_exists pacman; then
        sudo pacman -Syu kind --noconfirm 2>/dev/null || true
      fi
    fi
    echo "Kind 更新完成"
  else
    echo "Kind 未安装，跳过更新"
  fi
}

echo "更新 mise..."
update_mise

echo "更新 atuin..."
update_atuin

echo "更新 zoxide..."
update_zoxide

echo "更新 fzf..."
update_fzf

echo "更新 starship..."
update_starship

echo "更新 fd..."
update_fd

echo "更新 ripgrep..."
update_ripgrep

echo "更新 Docker..."
update_docker

echo "更新 Kind..."
update_kind

echo "更新系统包管理器..."
if [[ "$(uname)" == "Darwin" ]]; then
  if command_exists brew; then
    brew update 2>/dev/null || true
    brew upgrade 2>/dev/null || true
    echo "Homebrew 更新完成"
  fi
elif [[ "$(uname)" == "Linux" ]]; then
  if command_exists pacman; then
    sudo pacman -Syu --noconfirm 2>/dev/null || true
    echo "Pacman 更新完成"
  fi
fi

echo "=== 更新完成 ==="
