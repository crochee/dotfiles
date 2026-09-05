# system/hooks.fish —— fish 事件钩子审计
#
# 加载方：fish/config.fish 第 4 段（在 system/tools.fish 之后，避免被
# 后者的 prompt 覆盖抢先）
#
# 设计：
#   - 把 fish 启动 + 每次事件钩子触发写入 $XDG_CACHE_HOME/fish-hooks.log
#   - 行格式：<ISO8601> <event> <pid> <cwd>
#   - OMP（~/.config/omp/crochee.omp.json）的 shell_command 段读这个文件渲染
#   - 之后接审计系统时：直接 ship 这个文件 / 转 syslog 都行
#
# 注意：fish 自带 event 是 fish_prompt / precmd / postexec / preexec /
# fish_exit；用户自定义函数挂到这些 event 上时也会被记录（emit 的是函数名）
# 这里是"事件被触发"而非"所有用户函数都被调用"，要区分。

# 日志文件：保持在 $XDG_CACHE_HOME（fish config.fish 第 0 段已建好）
set -g __fish_hooks_log "$XDG_CACHE_HOME/fish-hooks.log"

# 写一行 + 截断（最近 200 行，审计够用、不爆磁盘）
function __fish_hooks_log_write --argument-names event
    set -l ts (date -u +%Y-%m-%dT%H:%M:%SZ)
    set -l pid %self
    set -l cwd (string replace --regex "^$HOME" "~" "$PWD")
    printf '%s %s pid=%s cwd=%s\n' "$ts" "$event" "$pid" "$cwd" \
        >> "$__fish_hooks_log"
    # 截断到 200 行
    set -l lines (wc -l < "$__fish_hooks_log" 2>/dev/null)
    if test "$lines" -gt 200
        tail -n 200 "$__fish_hooks_log" > "$__fish_hooks_log.tmp"
        mv "$__fish_hooks_log.tmp" "$__fish_hooks_log"
    end
end

# fish 启动即记一笔（确保审计能看到"这次会话启动了"）
__fish_hooks_log_write fish_startup

# 事件钩子 —— emit 不存在的 event 时静默忽略
# precmd 早于 prompt 触发，能抢在所有 prompt 渲染之前；OMP 的 fish_prompt
# 钩子必然被它覆盖一次（OMP 自己在 prompt event 上挂渲染函数）
function __fish_hooks_precmd --on-event precmd
    __fish_hooks_log_write precmd
end
function __fish_hooks_postexec --on-event postexec
    __fish_hooks_log_write postexec
end
function __fish_hooks_preexec --on-event preexec
    __fish_hooks_log_write preexec
end
function __fish_hooks_prompt --on-event fish_prompt
    __fish_hooks_log_write fish_prompt
end