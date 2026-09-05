# system/env.fish —— fish 版环境变量
#
# 加载方：fish/config.fish 第 1 段
# 镜像（已废弃）：原 system/env 是 bash 语法，fish 不 source .bashrc；现在 fish 是
# 唯一 shell，bash 端已全部清理。

set -gx CLICOLOR 1
set -gx COLORTERM truecolor
test -z "$LANG"; and set -gx LANG C.UTF-8

# 编辑器
set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx TERM xterm-256color
set -gx LESS "-R"
set -gx GREP_COLOR "36;40"

# XDG_* 在 config.fish 入口已设，这里不重复

# 密钥等敏感变量放在 system/.env.local（gitignored）
# .env.local 用 `KEY=VALUE` 行（不接 export），fish 用 while-read 解析
if test -r "$DOTFILES_DIR/system/.env.local"
    while read -l line
        # 跳过空行与注释行（# 或 export 前缀）
        set -l kv (string trim "$line")
        string match -qvr '^\s*(#|$|export\s)' "$kv"; or continue
        # 跳过 key 含非法字符的（fish 变量名规则：字母/数字/_，且非数字开头）
        set -l k (string split -m1 '=' "$kv")[1]
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' "$k"; or continue
        set -l v (string split -m1 '=' "$kv")[2]
        set -gx "$k" "$v"
    end < "$DOTFILES_DIR/system/.env.local"
end

# WSLg wayland 桥接：WSL2 下合成器 socket 实际挂在
# /mnt/wslg/runtime-dir/wayland-0，但 wl-copy / nvim clipboard 等工具只查
# $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY。源存在时软链一份过去（幂等，仅缺失时建），
# 原生 wayland 主机 /mnt/wslg 不存在 → 整块 no-op。
if test -S /mnt/wslg/runtime-dir/wayland-0; and test -n "$XDG_RUNTIME_DIR"
    switch "$WAYLAND_DISPLAY"
        case ''
        case 'wayland-0'
            set -gx WAYLAND_DISPLAY wayland-0
            test -S "$XDG_RUNTIME_DIR/wayland-0"; or ln -snf /mnt/wslg/runtime-dir/wayland-0 "$XDG_RUNTIME_DIR/wayland-0"
    end
end
