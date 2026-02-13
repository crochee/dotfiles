#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

ensure_ollama_user() {
    if id "ollama" &>/dev/null; then
        log_info "ollama 用户已存在"
    else
        log_info "创建 ollama 用户和组..."
        useradd -r -s /bin/false -U ollama
        log_success "ollama 用户创建成功"
    fi
}

check_ollama_binary() {
    local ollama_path="/bin/ollama"
    if [[ ! -x "$ollama_path" ]]; then
        ollama_path=$(command -v ollama 2>/dev/null || true)
    fi
    
    if [[ -z "$ollama_path" ]]; then
        log_error "未找到 ollama 二进制文件"
        log_info "请先安装 ollama: curl -fsSL https://ollama.com/install.sh | sh"
        exit 1
    fi
    
    log_info "找到 ollama: $ollama_path"
    echo "$ollama_path"
}

create_service() {
    local ollama_path="$1"
    
    log_info "创建 systemd 服务文件..."
    
    tee /etc/systemd/system/ollama.service > /dev/null << EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=${ollama_path} serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 /etc/systemd/system/ollama.service
    log_success "服务文件创建成功"
}

start_service() {
    log_info "重新加载 systemd..."
    systemctl daemon-reload
    
    log_info "启用 ollama 服务..."
    systemctl enable ollama
    
    log_info "启动 ollama 服务..."
    systemctl start ollama
    
    log_success "ollama 服务已启动"
    
    echo ""
    systemctl status ollama --no-pager || true
}

show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help     显示此帮助信息"
    echo "  --status   显示服务状态"
    echo ""
    echo "此脚本用于配置 ollama systemd 服务"
}

main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --status)
            systemctl status ollama --no-pager || true
            exit 0
            ;;
    esac
    
    log_info "开始配置 ollama 服务..."
    
    check_root
    ensure_ollama_user
    ollama_path=$(check_ollama_binary)
    create_service "$ollama_path"
    start_service
    
    echo ""
    log_success "ollama 服务配置完成!"
    log_info "使用 'ollama' 命令来管理模型"
}

main "$@"
