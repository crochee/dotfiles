#!/usr/bin/env bash

# dotfiles Mac 开发环境安装脚本
# 作者: crochee
# 版本: 1.0.0

set -euo pipefail # 严格错误处理

# 清理函数，用于脚本退出时执行
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "脚本执行失败，退出码: $exit_code"
        log "ERROR" "请检查日志输出以获取详细信息"
    fi

    # 清理临时文件（如果有）
    # 恢复环境变量（如果需要）

    return 0
}

# 设置退出陷阱
# trap cleanup EXIT

# 配置常量
script_path_tmp=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly SCRIPT_PATH="$script_path_tmp"
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
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
    "INFO") echo -e "${timestamp} ${BLUE}[INFO]${NC}  $message" ;;
    "WARN") echo -e "${timestamp} ${YELLOW}[WARN]${NC}  $message" ;;
    "ERROR") echo -e "${timestamp} ${RED}[ERROR]${NC} $message" ;;
    "SUCCESS") echo -e "${timestamp} ${GREEN}[SUCCESS]${NC} $message" ;;
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

# 检查 Homebrew 是否安装
check_brew() {
    if has_cmd "brew"; then
        log "INFO" "Homebrew 已安装"
        return 0
    else
        log "INFO" "Homebrew 未安装，开始安装..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1; then
            log "SUCCESS" "Homebrew 安装完成"
            # 添加 Homebrew 到 PATH
            if [ -f "$HOME/.zprofile" ]; then
                source "$HOME/.zprofile"
            elif [ -f "$HOME/.bash_profile" ]; then
                source "$HOME/.bash_profile"
            fi
            return 0
        else
            log "ERROR" "Homebrew 安装失败"
            return 1
        fi
    fi
}

# 使用 Homebrew 安装包
brew_install() {
    local package="$1"
    local description="${2:-$package}"
    
    if brew list "$package" >/dev/null 2>&1; then
        log "INFO" "$description 已安装"
        return 0
    fi
    
    log "INFO" "开始安装 $description..."
    if brew install "$package" >/dev/null 2>&1; then
        log "SUCCESS" "$description 安装完成"
        return 0
    else
        log "ERROR" "$description 安装失败"
        return 1
    fi
}

# 安装基础依赖
install_base_deps() {
    log "INFO" "安装基础开发依赖..."

    # 确保目录存在
    ensure_dir "$DOWNLOADS_DIR"
    ensure_dir "$LOCAL_BIN_DIR"

    # 检查并安装 Homebrew
    check_brew || return 1

    # 更新 Homebrew
    log "INFO" "更新 Homebrew..."
    if brew update >/dev/null 2>&1; then
        log "SUCCESS" "Homebrew 更新完成"
    else
        log "ERROR" "Homebrew 更新失败"
        return 1
    fi

    # 安装基础包
    local base_packages=(
        "curl"
        "wget"
        "unzip"
        "gcc"
    )

    log "INFO" "安装基础包: ${base_packages[*]}"
    for package in "${base_packages[@]}"; do
        brew_install "$package"
    done

    return 0
}

# 检查系统环境
check_system() {
    log "INFO" "检查系统环境..."

    # 检查是否在 Mac 上运行
    if [ "$(uname -s)" != "Darwin" ]; then
        log "ERROR" "此脚本仅适用于 Mac 系统"
        return 1
    fi
    log "SUCCESS" "在 Mac 上运行"

    return 0
}

# 安装 Rust
install_rust() {
    if has_cmd "cargo"; then
        log "INFO" "Rust 已安装"
        return 0
    fi

    if [ -z "${CARGO_HOME:-}" ]; then
        log "ERROR" "CARGO_HOME 环境变量未设置"
        log "ERROR" "请在运行脚本前设置 CARGO_HOME 环境变量，例如: export CARGO_HOME=/path/to/custom/dir"
        return 1
    fi

    log "INFO" "开始安装 Rust..."
    log "INFO" "CARGO_HOME 将被设置为: $CARGO_HOME"

    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path >/dev/null 2>&1; then
        log "SUCCESS" "Rust 安装完成"
        # 加载 rustup 环境配置
        if [ -f "$CARGO_HOME/env" ]; then
            log "INFO" "加载 Rust 环境配置: $CARGO_HOME/env"
            source "$CARGO_HOME/env" || log "WARN" "无法加载 Rust 环境配置"
        fi
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

    log "INFO" "开始安装 Go..."
    if brew_install "go" "Go 语言环境"; then
        log "SUCCESS" "Go 安装完成"
        return 0
    else
        log "ERROR" "Go 安装失败"
        return 1
    fi
}

# 安装 Python
install_python() {
    if has_cmd "python3"; then
        log "INFO" "Python 已安装"
        return 0
    fi

    log "INFO" "开始安装 Python..."
    if brew_install "python" "Python 环境"; then
        log "SUCCESS" "Python 安装完成"
        return 0
    else
        log "ERROR" "Python 安装失败"
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
    if brew_install "node" "Node.js 环境"; then
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
    if brew_install "openjdk" "Java 环境"; then
        log "SUCCESS" "Java 安装完成"
        return 0
    else
        log "ERROR" "Java 安装失败"
        return 1
    fi
}

# 安装 Docker
install_docker() {
    if has_cmd "docker"; then
        log "INFO" "Docker 已安装"
        return 0
    fi

    log "INFO" "开始安装 Docker..."
    if brew_install "docker" "Docker 环境"; then
        log "SUCCESS" "Docker 安装完成"
        log "INFO" "请确保 Docker Desktop 已安装并运行"
        return 0
    else
        log "ERROR" "Docker 安装失败"
        return 1
    fi
}

# 安装 Go 工具
install_go_tools() {
    if ! has_cmd "go"; then
        log "WARN" "Go 未安装，跳过 Go 工具安装"
        return 1
    fi

    local go_tools=("lazygit github.com/jesseduffield/lazygit@latest"
        "kind sigs.k8s.io/kind@latest"
        "kubebuilder sigs.k8s.io/kubebuilder/v4@latest")

    log "INFO" "开始安装 Go 工具..."

    for tool_spec in "${go_tools[@]}"; do
        read -r name tool <<<"$tool_spec"

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

    # 检查 GOPATH/bin 是否在 PATH 中
    if [[ ! "$PATH" =~ $GOPATH/bin ]]; then
        log "WARN" "$GOPATH/bin 不在 PATH 中，请添加到您的 shell 配置文件中"
        log "INFO" "例如: export PATH=\$PATH:\$GOPATH/bin"
    fi
}

# 安装 Cargo 工具
install_cargo_tools() {
    if ! has_cmd "cargo"; then
        log "WARN" "Cargo 未安装，跳过 Cargo 工具安装"
        return 1
    fi

    local cargo_tools=(
        "bat bat"
        "rg ripgrep"
        "fd fd-find"
        "zoxide zoxide"
        "mcfly mcfly"
        "uv uv"
    )

    log "INFO" "开始安装 Cargo 工具..."

    for tool_spec in "${cargo_tools[@]}"; do
        read -r name tool <<<"$tool_spec"

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

    # 检查 CARGO_HOME/bin 是否在 PATH 中
    if [ -n "$CARGO_HOME" ] && [[ ! "$PATH" =~ $CARGO_HOME/bin ]]; then
        log "WARN" "$CARGO_HOME/bin 不在 PATH 中，请添加到您的 shell 配置文件中"
        log "INFO" "例如: export PATH=\$PATH:\$CARGO_HOME/bin"
    fi
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
    local success=0

    install_go_tools || success=1
    install_cargo_tools || success=1
    install_uv_tools || success=1

    if [ $success -eq 0 ]; then
        log "SUCCESS" "所有开发工具安装完成"
    else
        log "WARN" "部分开发工具安装失败，请检查日志"
    fi

    return $success
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
        "nodejs")
            install_nodejs
            ;;
        "java")
            install_java
            ;;
        "docker")
            install_docker
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
    log "INFO" "交互式安装菜单"
    log "INFO" "请选择要安装的组件:"
    echo "使用空格分隔多个选项，或使用 'all' 选择所有组件，'q' 退出"
    echo

    # 显示所有可用组件
    local available_components=(
        "go Go 语言环境"
        "rust Rust 语言环境"
        "python Python 环境"
        "nodejs Node.js 环境"
        "java Java 环境"
        "docker Docker 环境"
        "tools 开发工具包"
        "base 基础开发依赖"
    )
    echo "可用组件:"
    for i in "${!available_components[@]}"; do
        read -r name description <<<"${available_components[$i]}"
        printf "  %-8s %s\n" "$name" "$description"
    done

    echo
    echo -n "请输入要安装的组件: "

    read -r choice

    case "$choice" in
    "quit" | "q" | "exit")
        log "INFO" "安装已取消"
        return 0
        ;;
    "all" | "ALL" | "All")
        log "INFO" "选择安装所有组件"
        install "go" "rust" "python" "nodejs" "java" "docker" "tools"
        ;;
    *)
        if [ -n "$choice" ]; then
            log "INFO" "选择安装组件: $choice"
            # 直接传递参数，不需要eval
            install "$choice"
        else
            log "WARN" "未选择任何组件"
        fi
        ;;
    esac

    echo
    log "INFO" "交互式安装完成"
}

# 显示帮助信息
show_help() {
    cat <<'EOF'
Mac 开发环境安装脚本

用法:
    $0 [选项]

选项:
    go          安装 Go 语言环境
    rust        安装 Rust 语言环境
    python      安装 Python 环境
    nodejs      安装 Node.js 环境
    java        安装 Java 环境
    docker      安装 Docker 环境
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
    log "INFO" "开始执行 Mac 开发环境安装"

    # 检查系统环境
    check_system || return 1

    # 切换到脚本目录
    cd "$SCRIPT_PATH"

    case "${1:-}" in
    "help" | "--help" | "-h")
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