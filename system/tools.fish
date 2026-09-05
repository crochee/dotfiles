# system/tools.fish —— fish 端工具初始化
# （原 system/tools.sh / system/tools.zsh 已废弃，本文件是 fish 唯一 init）
#
# 加载方：fish/config.fish 第 3 段
# 内容：mise / starship / zoxide 的 fish 端 init

# mise：PATH 前置 shims（与 bash/zsh 一致：shims 模式，不 full env）
if command -sq mise
    mise activate fish --shims | source
    # set -gx PATH (mise 内部已加)：避免重复
    fish_add_path --prepend "$HOME/.local/share/mise/shims"
end

# starship 提示符（P0：init 产物静态缓存——免每 shell spawn；文件由
# install/tools.sh 在 mise 升级后刷新，缺失时此处自愈生成一次）
if command -sq starship
    set -l _init_fish "$XDG_CACHE_HOME/dotfiles/starship-init.fish"
    if not test -s "$_init_fish"
        mkdir -p (dirname "$_init_fish") 2>/dev/null
        command starship init fish --print-full-init > "$_init_fish" 2>/dev/null
        or command rm -f "$_init_fish"
    end
    if test -s "$_init_fish"
        source "$_init_fish"
    else
        starship init fish | source
    end
    set -e _init_fish
end

# zoxide：智能目录跳转（接管 cd；P0 同 starship：init 产物静态缓存）
if command -sq zoxide
    set -gx _ZO_ECHO 1
    set -gx _ZO_MAXAGE 10000
    set -gx _ZO_DOCTOR 0
    set -l _init_fish "$XDG_CACHE_HOME/dotfiles/zoxide-init.fish"
    if not test -s "$_init_fish"
        mkdir -p (dirname "$_init_fish") 2>/dev/null
        command zoxide init fish --cmd cd > "$_init_fish" 2>/dev/null
        or command rm -f "$_init_fish"
    end
    if test -s "$_init_fish"
        source "$_init_fish"
    else
        zoxide init fish --cmd cd | source
    end
    set -e _init_fish
end
