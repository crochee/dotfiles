#!/usr/bin/env bash

# dotfiles 安装脚本
# 作者: crochee
# 版本: 1.0.0

set -euo pipefail # 严格错误处理

# 配置常量
readonly SOURCE="git@github.com:crochee/dotfiles.git"
readonly TARGET="$HOME/.dotfiles"
readonly SCRIPT_NAME="dotfiles-install"

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
    "INFO") echo -e "${timestamp} ${BLUE}[INFO]${NC}  $message" ;;
    "WARN") echo -e "${timestamp} ${YELLOW}[WARN]${NC}  $message" ;;
    "ERROR") echo -e "${timestamp} ${RED}[ERROR]${NC} $message" ;;
    "SUCCESS") echo -e "${timestamp} ${GREEN}[OK]${NC}   $message" ;;
    esac
}

# 标题显示
show_title() {
    local title="$1"
    printf '\n%s\n' "======== $title ========" | tr '[:lower:]' '[:upper:]'
}

# 检查命令是否存在
check_commands() {
    local missing=()
    local idx=1

    for cmd in "$@"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log "INFO" "${idx}. $cmd ✓"
        else
            log "ERROR" "${idx}. $cmd ✗"
            missing+=("$cmd")
        fi
        ((idx++))
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log "ERROR" "缺少必要命令: ${missing[*]}"
        return 1
    fi
    return 0
}

# 创建备份目录
create_backup_dir() {
    local backup_dir="$HOME/backup_$(date +%Y-%m-%d_%H-%M-%S)"
    log "INFO" "创建备份目录: $backup_dir"
    if ! mkdir -p "$backup_dir" >/dev/null 2>&1; then
        log "ERROR" "备份目录创建失败"
        return 1
    fi
    log "SUCCESS" "备份目录创建成功"
    echo "$backup_dir"
}

# 备份文件
backup_file() {
    local file="$1"
    local backup_dir="$2"
    log "INFO" "备份现有文件: $file -> $backup_dir/"
    if ! mv "$file" "$backup_dir/" >/dev/null 2>&1; then
        log "ERROR" "文件备份失败"
        return 1
    fi
    log "SUCCESS" "文件备份成功"
    return 0
}

# 创建符号链接
create_symlink() {
    local source="$1"
    local target="$2"

    # 检查源文件是否存在
    if [ ! -e "$source" ]; then
        log "ERROR" "源文件不存在: $source"
        return 1
    fi

    # 如果目标已存在，先备份
    if [ -e "$target" ]; then
        local backup_dir=$(create_backup_dir 2>&1 | tail -n 1)
        if [ -z "$backup_dir" ]; then
            log "ERROR" "无法获取备份目录"
            return 1
        fi
        if ! backup_file "$target" "$backup_dir"; then
            return 1
        fi
    fi

    # 创建符号链接
    log "INFO" "创建符号链接: $source -> $target"
    if ln -sf "$source" "$target" >/dev/null 2>&1; then
        log "SUCCESS" "符号链接创建成功"
        return 0
    else
        log "ERROR" "符号链接创建失败"
        return 1
    fi
}

# 克隆仓库
clone_repository() {
    local tarball_url="$SOURCE/tarball/master"
    local tar_cmd="tar -xzv -C $TARGET --strip-components=1 --exclude='.gitignore'"
    local cmd=""

    # 按优先级选择工具
    if command -v git >/dev/null 2>&1; then
        cmd="git clone --depth 1 $SOURCE $TARGET"
        log "INFO" "使用 git 克隆仓库"
    elif command -v curl >/dev/null 2>&1; then
        cmd="curl -#L $tarball_url | $tar_cmd"
        log "INFO" "使用 curl 下载"
    elif command -v wget >/dev/null 2>&1; then
        cmd="wget --no-check-certificate -O - $tarball_url | $tar_cmd"
        log "INFO" "使用 wget 下载"
    else
        log "ERROR" "未找到 git、curl 或 wget，无法继续安装"
        return 1
    fi

    log "INFO" "开始克隆 dotfiles..."
    mkdir -p "$TARGET"

    if eval "$cmd"; then
        log "SUCCESS" "dotfiles 克隆成功"
        return 0
    else
        log "ERROR" "dotfiles 克隆失败"
        return 1
    fi
}

# 检查并准备仓库
prepare_repository() {
    log "INFO" "检查 dotfiles 仓库..."

    if [ -d "$TARGET/.git" ]; then
        log "SUCCESS" "仓库已存在"
        return 0
    else
        log "INFO" "仓库不存在，开始克隆"
        if clone_repository; then
            return 0
        else
            return 1
        fi
    fi
}

# 处理特殊目录
handle_special_dir() {
    local dir="$1"
    local target_dir="$2"
    local dir_name=$(basename "$dir")

    case "$dir_name" in
    "cargo")
        # 确保 cargo 目录存在
        if ! mkdir -p "$target_dir/$dir_name" >/dev/null 2>&1; then
            log "ERROR" "无法创建 cargo 目录: $target_dir/$dir_name"
            return 1
        fi
        
        # 检查 config.toml 文件是否存在
        if [ -f "$dir/config.toml" ]; then
            create_symlink "$dir/config.toml" "$target_dir/$dir_name/config.toml" || return 1
        else
            log "WARN" "跳过 cargo 目录，因为 config.toml 文件不存在: $dir"
            return 0
        fi
        ;;
    "starship")
        # 检查 starship.toml 文件是否存在
        if [ -f "$dir/starship.toml" ]; then
            create_symlink "$dir/starship.toml" "$target_dir/starship.toml" || return 1
        else
            log "WARN" "跳过 starship 目录，因为 starship.toml 文件不存在: $dir"
            return 0
        fi
        ;;
    *)
        # 其他目录直接创建符号链接
        create_symlink "$dir" "$target_dir/$dir_name" || return 1
        ;;
    esac
    return 0
}

# 验证安装结果
verify_install() {
    local source_dir="$1"
    local target_dir="$2"
    local description="$3"

    log "INFO" "验证 $description 安装结果..."
    local success_count=0
    local total_count=0

    # 验证目录
    find "$source_dir" -maxdepth 1 -type d ! -name "$(basename "$source_dir")" | while read -r dir; do
        local dir_name=$(basename "$dir")
        total_count=$((total_count + 1))
        
        case "$dir_name" in
        "starship")
            # 验证 starship 配置文件
            if [ -f "$target_dir/starship.toml" ]; then
                success_count=$((success_count + 1))
            else
                log "WARN" "验证失败: $target_dir/starship.toml"
            fi
            ;;
        *)
            # 验证其他目录
            if [ -L "$target_dir/$dir_name" ]; then
                success_count=$((success_count + 1))
            else
                log "WARN" "验证失败: $target_dir/$dir_name"
            fi
            ;;
        esac
    done

    # 验证文件
    find "$source_dir" -maxdepth 1 -type f | while read -r file; do
        local filename=$(basename "$file")
        total_count=$((total_count + 1))
        if [ -L "$target_dir/$filename" ]; then
            success_count=$((success_count + 1))
        else
            log "WARN" "验证失败: $target_dir/$filename"
        fi
    done

    if [ $total_count -gt 0 ]; then
        log "INFO" "安装结果: $success_count/$total_count 个项目安装成功"
    fi
}

# 通用安装函数
install_files() {
    local source_dir="$1"
    local target_dir="$2"
    local description="$3"

    if [ ! -d "$source_dir" ]; then
        log "WARN" "$description 目录不存在: $source_dir"
        return 0
    fi

    log "INFO" "安装 $description..."

    # 确保目标目录存在
    if ! mkdir -p "$target_dir" >/dev/null 2>&1; then
        log "ERROR" "无法创建目标目录: $target_dir"
        return 1
    fi

    # 处理目录
    find "$source_dir" -maxdepth 1 -type d ! -name "$(basename "$source_dir")" | while read -r dir; do
        # 检查目录是否为空
        if [ -z "$(ls -A "$dir")" ]; then
            log "WARN" "跳过空目录: $dir"
            continue
        fi
        handle_special_dir "$dir" "$target_dir" || continue
    done

    # 处理文件
    find "$source_dir" -maxdepth 1 -type f | while read -r file; do
        local filename=$(basename "$file")
        create_symlink "$file" "$target_dir/$filename" || continue
    done

    # 验证安装结果
    verify_install "$source_dir" "$target_dir" "$description"

    log "SUCCESS" "$description 安装完成"
}

# 安装 dotfiles
install_dotfiles() {
    install_files "$TARGET/dotfiles" "$HOME" "dotfiles"
}

# 安装配置文件
install_config() {
    mkdir -p "$HOME/.config"
    install_files "$TARGET/config" "$HOME/.config" "配置文件"
}

# 安装 zk 配置
install_zk() {
    local zk_dir="$HOME/.config/notes"

    if [ ! -d "$zk_dir" ]; then
        log "INFO" "创建新的 notes 目录"
        mkdir -p "$zk_dir"
    fi

    create_symlink "$TARGET/zk" "$zk_dir/.zk" || return 1
    log "SUCCESS" "zk 配置安装完成"
}

# 初始化 bashrc
init_bashrc() {
    local bashrc_path="$HOME/.bashrc"
    local dotfiles_source="source $HOME/.dotfiles/.bashrc"

    if [ ! -f "$bashrc_path" ]; then
        log "INFO" "创建新的 .bashrc 文件"
        touch "$bashrc_path"
    fi

    if grep -q "source $HOME/.dotfiles/.bashrc" "$bashrc_path"; then
        log "INFO" ".bashrc 已包含 dotfiles 引用"
    else
        log "INFO" "向 .bashrc 添加 dotfiles 引用"
        echo "$dotfiles_source" >>"$bashrc_path"
    fi
}

# 设置可执行权限
set_executable_permissions() {
    local bin_dir="$TARGET/bin"

    if [ -d "$bin_dir" ]; then
        log "INFO" "设置 bin 目录文件执行权限"
        find "$bin_dir" -type f -exec chmod a+x {} + >/dev/null 2>&1 ||
            log "WARN" "设置部分文件权限失败"
    fi
}

# 显示安装菜单
show_install_menu() {
    show_title "INSTALL"
    echo "1) 安装配置文件"
    echo "2) 安装 dotfiles"
    echo "3) 安装 dotfiles 和配置文件"
    echo "4) 安装 zk 配置"
    echo
    read -r -p "请选择安装选项 [1-4]: " choice

    case "$choice" in
    1) run_install install_config ;;
    2) run_install install_dotfiles ;;
    3) run_install install_dotfiles install_config ;;
    4) run_install install_zk ;;
    *) log "ERROR" "无效选项: $choice" && return 1 ;;
    esac
}

# 运行安装流程
run_install() {
    if ! prepare_repository; then
        log "ERROR" "仓库准备失败，安装中止"
        return 1
    fi

    # 执行所有传入的安装函数
    for func in "$@"; do
        if ! $func; then
            log "ERROR" "$func 安装失败"
            return 1
        fi
    done

    log "SUCCESS" "所有选中项目安装完成"
    return 0
}

# 显示帮助信息
show_help() {
    cat <<'EOF'
dotfiles 安装脚本

用法:
    $0 [选项]

选项:
    1       安装配置文件
    2       安装 dotfiles
    3       安装 dotfiles 和配置文件
    4       安装 zk 配置
    5       安装共享文件
    -h, --help  显示此帮助信息

示例:
    $0              # 显示交互式菜单
    $0 3            # 安装 dotfiles 和配置文件
    $0 install      # 显示帮助信息

EOF
}

# 主函数
main() {
    log "INFO" "开始执行 $SCRIPT_NAME 安装脚本"

    # 检查基本命令
    if ! check_commands "find" "ln" "mkdir" "touch" "grep"; then
        exit 1
    fi

    # 初始化 bashrc
    init_bashrc

    # 设置可执行权限
    set_executable_permissions

    case "${1:-}" in
    -h | --help | help)
        show_help
        ;;
    "")
        show_install_menu
        ;;
    1)
        run_install install_config
        ;;
    2)
        run_install install_dotfiles
        ;;
    3)
        run_install install_dotfiles install_config
        ;;
    4)
        run_install install_zk
        ;;
    *)
        log "ERROR" "无效选项: $1"
        show_help
        ;;
    esac

    log "INFO" "安装脚本执行完成"
}

# 清理函数
cleanup() {
    log "INFO" "执行清理操作..."
    # 这里可以添加清理代码
}

# 设置陷阱
trap cleanup EXIT

# 执行主函数
main "$@"