#!/usr/bin/env bash

set -euo pipefail

echo "=== 开始安装工具 ==="

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_mise() {
  if command_exists mise; then
    return 0
  fi
  echo "安装 mise..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install mise
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu mise --noconfirm
    else
      sudo apt install mise -y
    fi
  else
    curl -L https://github.com/jdx/mise/releases/latest/download/mise-linux-x86_64.tar.gz | tar -xzf - -C ~/.local/bin
  fi
  echo "mise 安装完成"
}

install_atuin() {
  if command_exists atuin; then
    return 0
  fi
  echo "安装 atuin..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install atuin
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu atuin --noconfirm
    else
      sudo apt install atuin -y
    fi
  else
    curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz | tar -xzf - -C ~/.local/bin
  fi
  
  echo "atuin 安装完成"
}

install_zoxide() {
  if command_exists zoxide; then
    return 0
  fi
  echo "安装 zoxide..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install zoxide
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu zoxide --noconfirm
    elif command_exists apt; then
      sudo apt install zoxide -y
    elif command_exists cargo; then
      cargo install zoxide
    else
      echo "zoxide 未安装且无法使用 pacman 或 apt 或 cargo 安装"
    fi
  else
    curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi
  echo "zoxide 安装完成"
}

install_fzf() {
  if command_exists fzf; then
    return 0
  fi
  echo "安装 fzf..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install fzf
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu fzf --noconfirm
    elif command_exists apt; then
      sudo apt install fzf -y
    elif command_exists cargo; then
      cargo install fzf
    else
      echo "fzf 未安装且无法使用 pacman 或 apt 或 cargo 安装"
    fi
  else
    curl -sSf https://raw.githubusercontent.com/junegunn/fzf/main/install.sh | sh
  fi
  echo "fzf 安装完成"
}

install_starship() {
  if command_exists starship; then
    return 0
  fi
  echo "安装 starship..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install starship
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu starship --noconfirm
    elif command_exists apt; then
      sudo apt install starship -y
    elif command_exists cargo; then
      cargo install starship
    else
      echo "starship 未安装且无法使用 pacman 或 apt 或 cargo 安装"
    fi
  else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  echo "starship 安装完成"
}

install_fd() {
  if command_exists fd; then
    return 0
  fi
  echo "安装 fd..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install fd
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu fd --noconfirm
    elif command_exists apt; then
      sudo apt install fd-find -y
    elif command_exists cargo; then
      cargo install fd-find
    else
      local FD_VERSION="9.0.0"
      curl -L "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xzf - -C ~/.local/bin
    fi
  fi
  echo "fd 安装完成"
}

install_ripgrep() {
  if command_exists rg; then
    return 0
  fi
  echo "安装 ripgrep..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ripgrep
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu ripgrep --noconfirm
    elif command_exists apt; then
      sudo apt install ripgrep -y
    elif command_exists cargo; then
      cargo install ripgrep
    else
      local RG_VERSION="14.1.0"
      curl -L "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xzf - -C ~/.local/bin
    fi
  fi
  echo "ripgrep 安装完成"
}

install_docker() {
  if command_exists docker; then
    return 0
  fi
  echo "安装 Docker..."
  if [[ "$(uname)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install docker
    else
      echo "Docker 未安装且无法使用 brew 安装"
    fi
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu docker --noconfirm
    elif command_exists apt; then
      sudo apt install docker -y
    else
      echo "Docker 未安装且无法使用 pacman 或 apt 安装"
    fi
  fi
  echo "Docker 安装完成"
}

install_kind() {
  if command_exists kind; then
    return 0
  fi
  echo "安装 Kind..."
  if command_exists go; then
    go install sigs.k8s.io/kind@latest
  elif [[ "$(uname)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install kind
    else
      local KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4 | cut -c2-)
      curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-darwin-amd64"
      chmod +x /tmp/kind
      sudo mv /tmp/kind /usr/local/bin/kind
    fi
  elif [[ "$(uname)" == "Linux" ]]; then
    if command_exists pacman; then
      sudo pacman -Syu kind --noconfirm
    elif command_exists apt; then
      local KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4 | cut -c2-)
      curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
      chmod +x /tmp/kind
      sudo mv /tmp/kind /usr/local/bin/kind
    else
      local KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4 | cut -c2-)
      curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
      chmod +x /tmp/kind
      sudo mv /tmp/kind /usr/local/bin/kind
    fi
  fi
  echo "Kind 安装完成"
}

install_mise
install_atuin
install_zoxide
install_fzf
install_starship
install_fd
install_ripgrep
install_docker
install_kind

echo "=== 安装完成 ==="
