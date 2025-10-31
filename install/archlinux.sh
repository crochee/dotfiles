#!/usr/bin/env bash

# dotfiles Arch Linux 开发环境安装脚本
# 作者: crochee
# 版本: 1.0.0

set -euo pipefail  # 严格错误处理

# 配置常量
readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly HOME_DIR="$HOME"
readonly DOWNLOADS_DIR="$HOME/Downloads"
readonly LOCAL_BIN_DIR="$HOME/.local/bin"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  echo -e "${timestamp} ${BLUE}[INFO]${NC}  $message" ;;
        "WARN")  echo -e "${timestamp} ${YELLOW}[WARN]${NC}  $message" ;;
        "ERROR") echo -e "${timestamp} ${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${timestamp} ${GREEN}[OK]${NC}   $message" ;;
        "CHECK") echo -en "${timestamp} $message " ;;
    esac
}

# 检查命令是否存在
has_cmd() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        log "CHECK" "$cmd"
        echo -e "${GREEN}√${NC}"
        return 0
    else
        log "CHECK" "$cmd"
        echo -e "${RED}✘${NC}"
        return 1
    fi
}

# 检查目录存在性，不存在则创建
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        log "INFO" "创建目录: $dir"
        if mkdir -p "$dir" >/dev/null 2>&1; then
            log "SUCCESS" "目录创建成功"
        else
            log "ERROR" "目录创建失败: $dir"
            return 1
        fi
    fi
    return 0
}

# 安装 Rust
install_rust() {
    if has_cmd "cargo"; then
        log "INFO" "Rust 已安装"
        return 0
    fi

    if [ -z "${CARGO_HOME:-}" ]; then
        log "WARN" "CARGO_HOME 环境变量未设置"
        return 1
    fi

    log "INFO" "开始安装 Rust..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh >/dev/null 2>&1; then
        log "SUCCESS" "Rust 安装完成"
        # 重新加载环境变量
        source "$HOME/.bashrc" || log "WARN" "无法加载 bashrc"
        return 0
    else
        log "ERROR" "Rust 安装失败"
        return 1
    fi
}

# 安装 Go
install_go() {
    if has_cmd "go"; then
        log "INFO" "Go 已安装"
        return 0
    fi

    if [ -z "${GOROOT:-}" ] || [ ! -d "$GOROOT" ]; then
        log "ERROR" "GOROOT 环境变量未设置或目录不存在"
        return 1
    fi

    local go_version="1.24.5"
    local go_tarball="go${go_version}.linux-amd64.tar.gz"
    local go_url="https://dl.google.com/go/$go_tarball"

    log "INFO" "开始安装 Go $go_version..."

    # 确保下载目录存在
    ensure_dir "$DOWNLOADS_DIR" || return 1

    # 下载 Go
    cd "$DOWNLOADS_DIR"
    if curl -#L "$go_url" -o "$go_tarball"; then
        # 解压并安装
        if tar -C "$GOROOT" -xzf "$go_tarball"; then
            # 重命名目录
            if mv "$GOROOT/go" "$GOROOT/go${go_version}" 2>/dev/null; then
                log "SUCCESS" "Go 安装完成"
                # 重新加载环境变量
                source "$HOME/.bashrc" || log "WARN" "无法加载 bashrc"
                cd "$SCRIPT_PATH"
                unset go_version go_tarball go_url
                return 0
            else
                log "ERROR" "Go 目录重命名失败"
                return 1
            fi
        else
            log "ERROR" "Go 解压失败"
            return 1
        fi
    else
        log "ERROR" "Go 下载失败"
        return 1
    fi
}

# 安装 Python
install_python() {
    if has_cmd "python"; then
        log "INFO" "Python 已安装"
        return 0
    fi

    log "INFO" "开始安装 Python..."
    if sudo pacman -S --noconfirm python >/dev/null 2>&1; then
        log "SUCCESS" "Python 安装完成"
        return 0
    else
        log "ERROR" "Python 安装失败"
        return 1
    fi
}

# 安装 rsync
install_rsync() {
    if has_cmd "rsync"; then
        log "INFO" "rsync 已安装"
        return 0
    fi

    log "INFO" "开始安装 rsync..."
    if sudo pacman -S --noconfirm rsync >/dev/null 2>&1; then
        log "SUCCESS" "rsync 安装完成"
        return 0
    else
        log "ERROR" "rsync 安装失败"
        return 1
    fi
}

# 安装 Node.js
install_nodejs() {
    if has_cmd "node"; then
        log "INFO" "Node.js 已安装"
        return 0
    fi

    log "INFO" "开始安装 Node.js..."
    if sudo pacman -S --noconfirm nodejs >/dev/null 2>&1; then
        log "SUCCESS" "Node.js 安装完成"
        return 0
    else
        log "ERROR" "Node.js 安装失败"
        return 1
    fi
}

# 安装 Java
install_java() {
    if has_cmd "java"; then
        log "INFO" "Java 已安装"
        return 0
    fi

    log "INFO" "开始安装 Java..."
    if sudo pacman -S --noconfirm jdk17-openjdk >/dev/null 2>&1; then
        log "SUCCESS" "Java 安装完成"
        return 0
    else
        log "ERROR" "Java 安装失败"
        return 1
    fi
}

# 安装 Go 工具
install_go_tools() {
    if ! has_cmd "go"; then
        log "WARN" "Go 未安装，跳过 Go 工具安装"
        return 1
    fi

    local tools=(
        "github.com/jesseduffield/lazygit@latest"
        "sigs.k8s.io/kind@latest"
        "sigs.k8s.io/kubebuilder/v4@latest"
    )
    local tool_names=("lazygit" "kind" "kubebuilder")

    log "INFO" "开始安装 Go 工具..."

    for i in "${!tools[@]}"; do
        local tool="${tools[$i]}"
        local name="${tool_names[$i]}"

        if has_cmd "$name"; then
            log "INFO" "$name 已安装"
            continue
        fi

        log "INFO" "安装 $name..."
        if go install "$tool" >/dev/null 2>&1; then
            log "SUCCESS" "$name 安装完成"
        else
            log "ERROR" "$name 安装失败"
        fi
    done
}

# 安装 Cargo 工具
install_cargo_tools() {
    if ! has_cmd "cargo"; then
        log "WARN" "Cargo 未安装，跳过 Cargo 工具安装"
        return 1
    fi

    local tools=(
        "bat"
        "ripgrep"
        "fd-find"
        "zoxide"
        "mcfly"
        "--git https://github.com/astral-sh/uv uv"
    )
    local tool_names=("bat" "rg" "fd" "zoxide" "mcfly" "uv")

    log "INFO" "开始安装 Cargo 工具..."

    for i in "${!tools[@]}"; do
        local tool="${tools[$i]}"
        local name="${tool_names[$i]}"

        if has_cmd "$name"; then
            log "INFO" "$name 已安装"
            continue
        fi

        log "INFO" "安装 $name..."
        if cargo install "$tool" >/dev/null 2>&1; then
            log "SUCCESS" "$name 安装完成"
        else
            log "ERROR" "$name 安装失败"
        fi
    done
}

# 安装 uv 相关工具
install_uv_tools() {
    if ! has_cmd "uv"; then
        log "WARN" "uv 未安装，跳过 uv 工具安装"
        return 1
    fi

    if has_cmd "mycli"; then
        log "INFO" "mycli 已安装"
        return 0
    fi

    log "INFO" "开始安装 mycli..."
    # 检查虚拟环境
    if [ -d "$HOME/.venv" ] && [ -f "$HOME/.venv/bin/activate" ]; then
        if source "$HOME/.venv/bin/activate" && uv pip install mycli >/dev/null 2>&1; then
            log "SUCCESS" "mycli 安装完成"
        else
            log "ERROR" "mycli 安装失败"
        fi
    else
        log "WARN" "虚拟环境不存在，跳过 mycli 安装"
    fi
}

# 安装所有工具
install_tools() {
    log "INFO" "开始安装开发工具..."

    install_go_tools
    install_cargo_tools
    install_uv_tools

    log "SUCCESS" "开发工具安装完成"
}

# 安装基础依赖
install_base_deps() {
    log "INFO" "安装基础开发依赖..."

    # 确保目录存在
    ensure_dir "$DOWNLOADS_DIR"
    ensure_dir "$LOCAL_BIN_DIR"

    # 安装基础包
    local base_packages=(
        "base-devel"
        "curl"
        "wget"
        "unzip"
        "gcc"
    )

    for package in "${base_packages[@]}"; do
        if ! has_cmd "$package" >/dev/null 2>&1; then
            log "INFO" "安装 $package..."
            if sudo pacman -S --noconfirm "$package" >/dev/null 2>&1; then
                log "SUCCESS" "$package 安装完成"
            else
                log "ERROR" "$package 安装失败"
            fi
        fi
    done
}

# 初始化安装流程
install() {
    for component in "$@"; do
        case "$component" in
            "go")
                install_go
                ;;
            "rust")
                install_rust
                ;;
            "python")
                install_python
                ;;
            "rsync")
                install_rsync
                ;;
            "nodejs")
                install_nodejs
                ;;
            "java")
                install_java
                ;;
            "tools")
                install_tools
                ;;
            "base")
                install_base_deps
                ;;
            *)
                log "ERROR" "未知组件: $component"
                return 1
                ;;
        esac
    done
}

# 显示安装菜单
show_menu() {
    # 安装基础依赖
    install_base_deps

    echo
    log "INFO" "请选择要安装的组件:"
    echo "可用选项: go, rust, python, nodejs, java, rsync, tools, base 或 quit"
    echo -n "选择: "

    read -r choice

    case "$choice" in
        "quit"|"q"|"exit")
            log "INFO" "安装已取消"
            return 0
            ;;
        *)
            install $choice
            ;;
    esac
}

# 显示帮助信息
show_help() {
    cat << 'EOF'
Arch Linux 开发环境安装脚本

用法:
    $0 [选项]

选项:
    go          安装 Go 语言环境
    rust        安装 Rust 语言环境
    python      安装 Python 环境
    nodejs      安装 Node.js 环境
    java        安装 Java 环境
    rsync       安装 rsync 工具
    tools       安装开发工具 (lazygit, kind, kubebuilder, bat, ripgrep, fd, zoxide, mcfly, uv)
    base        安装基础开发依赖
    help        显示此帮助信息

示例:
    $0              # 显示交互式菜单
    $0 go rust      # 安装 Go 和 Rust
    $0 tools        # 安装所有开发工具

EOF
}

# 主函数
main() {
    log "INFO" "开始执行 Arch Linux 开发环境安装"

    # 切换到脚本目录
    cd "$SCRIPT_PATH"

    case "${1:-}" in
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            show_menu
            ;;
        *)
            install_base_deps
            install "$@"
            ;;
    esac

    log "INFO" "安装完成"
}

# 执行主函数
main "$@"
