# 定义颜色和工具函数
_setup_colors() {
    local ESC_OPEN="\["  
    local ESC_CLOSE="\]"
    local RESET=""
    local BOLD=""
    local DIM=""

    # 检查终端是否支持颜色
    if tput setaf >/dev/null 2>&1 && tput sgr0 >/dev/null 2>&1; then
        # 支持 tput 的终端
        _setaf() { tput setaf "$1"; }
        RESET="${ESC_OPEN}$(tput sgr0 2>/dev/null || tput me 2>/dev/null)${ESC_CLOSE}"
        BOLD="${ESC_OPEN}$(tput bold 2>/dev/null)${ESC_CLOSE}"
        DIM="${ESC_OPEN}$(tput dim 2>/dev/null)${ESC_CLOSE}"
    else
        # 不支持 tput 的终端，使用 ANSI 转义序列
        _setaf() { printf "\033[0;%sm" $(($1 + 30)); }
        RESET="\033[m"
        BOLD="\033[1m"
        DIM="\033[2m"
        ESC_OPEN=""
        ESC_CLOSE=""
    fi

    # 定义基础颜色
    local BLACK="${ESC_OPEN}$(_setaf 0)${ESC_CLOSE}"
    local RED="${ESC_OPEN}$(_setaf 1)${ESC_CLOSE}"
    local GREEN="${ESC_OPEN}$(_setaf 2)${ESC_CLOSE}"
    local YELLOW="${ESC_OPEN}$(_setaf 3)${ESC_CLOSE}"
    local BLUE="${ESC_OPEN}$(_setaf 4)${ESC_CLOSE}"
    local MAGENTA="${ESC_OPEN}$(_setaf 5)${ESC_CLOSE}"
    local CYAN="${ESC_OPEN}$(_setaf 6)${ESC_CLOSE}"
    local WHITE="${ESC_OPEN}$(_setaf 7)${ESC_CLOSE}"

    # 定义亮色
    local BRIGHT_BLACK="${ESC_OPEN}$(_setaf 8)${ESC_CLOSE}"
    local BRIGHT_RED="${ESC_OPEN}$(_setaf 9)${ESC_CLOSE}"
    local BRIGHT_GREEN="${ESC_OPEN}$(_setaf 10)${ESC_CLOSE}"
    local BRIGHT_YELLOW="${ESC_OPEN}$(_setaf 11)${ESC_CLOSE}"
    local BRIGHT_BLUE="${ESC_OPEN}$(_setaf 12)${ESC_CLOSE}"
    local BRIGHT_MAGENTA="${ESC_OPEN}$(_setaf 13)${ESC_CLOSE}"
    local BRIGHT_CYAN="${ESC_OPEN}$(_setaf 14)${ESC_CLOSE}"
    local BRIGHT_WHITE="${ESC_OPEN}$(_setaf 15)${ESC_CLOSE}"

    # 暴露颜色变量供提示符使用
    P_USER=${BRIGHT_MAGENTA}
    P_HOST=${BRIGHT_GREEN}
    P_WHITE=${WHITE}
    P_YELLOW=${YELLOW}
    P_RED=${RED}
    P_BLUE=${BLUE}
    P_BRIGHT_BLUE=${BRIGHT_BLUE}
    P_GREEN=${GREEN}
    P_RESET=${RESET}
    P_BOLD=${BOLD}
    P_DIM=${DIM}
}

# 解析 Git 信息
parse_git() {
    # 快速检查是否在 Git 仓库中
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    # 获取 Git 分支名或标签名
    local git_ref=""
    git_ref=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z "$git_ref" ]]; then
        git_ref=$(git describe --tags --exact-match HEAD 2>/dev/null)
        if [[ -z "$git_ref" ]]; then
            return
        fi
    fi

    # 检查是否有未提交的改动
    local git_dirty="✓"
    if [[ -n $(git status --porcelain --ignore-submodules -uno 2>/dev/null) ]]; then
        git_dirty="${P_RED}*"
    fi

    # 获取与上游分支相差的 commit 数量
    local git_commit=""
    local upstream_branch=$(git rev-parse --symbolic-full-name --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream_branch" ]]; then
        local commits_behind=$(git rev-list --count --max-count=100 HEAD..@{u} 2>/dev/null || echo 0)
        local commits_ahead=$(git rev-list --count --max-count=100 @{u}..HEAD 2>/dev/null || echo 0)
        
        [[ $commits_behind -gt 0 ]] && git_commit+="↓$commits_behind"
        [[ $commits_ahead -gt 0 ]] && git_commit+="↑$commits_ahead"
        [[ -n "$git_commit" ]] && git_commit="${git_commit} "
    fi

    # 检查是否有 stash
    local git_stash=""
    if [[ -f "$(git rev-parse --git-dir 2>/dev/null)/refs/stash" ]]; then
        git_stash="${P_BLUE}⚑"
    fi

    # 检查是否处于 rebase 或 merge 状态
    local git_state=""
    local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
    if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
        git_state="${P_RED}↦"
    elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
        git_state="${P_RED}⚡"
    fi

    echo "${P_YELLOW}(${git_ref} ${git_commit}${git_dirty}${git_stash}${git_state}${P_YELLOW})"
}

# 主提示符函数
bash_prompt_command() {
    local EXIT_CODE=$?
    local P_EXIT=""
    local MAXLENGTH=35
    local TRUNC_SYMBOL=".."
    local P_PWD=${PWD/#$HOME/\~}

    # 智能截断过长的路径
    if [[ ${#P_PWD} -gt $MAXLENGTH ]]; then
        local dirs=()
        local path="$P_PWD"
        local truncated=""
        local total_length=0
        
        # 分割路径为目录数组
        while [[ -n "$path" ]]; do
            local dir="${path##*/}"
            dirs=($dir "${dirs[@]}")
            path="${path%/*}"
            [[ "$dir" != "" ]] && path="${path%/}"
        done
        
        local num_dirs=${#dirs[@]}
        local i
        
        # 如果只有一个目录，直接截断
        if [[ $num_dirs -eq 1 ]]; then
            P_PWD="${TRUNC_SYMBOL}/${P_PWD: -$((MAXLENGTH - ${#TRUNC_SYMBOL} - 1))}"
            return
        fi
        
        # 从路径末尾开始添加目录，直到达到最大长度
        for ((i = num_dirs - 1; i >= 0; i--)); do
            local dir="${dirs[i]}"
            local dir_length=${#dir}
            
            # 如果是第一个目录（可能是 ~ 或 /），特殊处理
            if [[ $i -eq 0 ]]; then
                if [[ ${#truncated} -eq 0 ]]; then
                    truncated="$dir"
                else
                    truncated="$dir/$truncated"
                fi
            else
                # 如果目录名太长，只保留前几个字符
                if [[ $dir_length -gt 10 ]]; then
                    dir="${dir:0:7}..."
                    dir_length=10
                fi
                
                if [[ $i -eq $((num_dirs - 1)) ]]; then
                    truncated="$dir"
                else
                    truncated="$dir/$truncated"
                fi
            fi
            
            total_length=${#truncated}
            
            # 如果总长度超过最大长度，添加截断符号并退出
            if [[ $total_length -gt $MAXLENGTH ]]; then
                P_PWD="${TRUNC_SYMBOL}/${truncated}"
                return
            fi
        done
        
        P_PWD="$truncated"
    fi

    # 更新终端标题
    if [[ $TERM == xterm* ]]; then
        echo -ne "\033]0;${P_PWD}\007"
    fi

    # 处理退出状态码
    if [[ $EXIT_CODE != 0 ]]; then
        P_EXIT+="${P_RED}✘ "
    fi

    # 构建提示符
    # 添加时间、用户、主机、路径、Git 信息和退出状态
    PS1="${P_WHITE}{${P_YELLOW}$(date +"%y-%m-%d %H:%M:%S")${P_WHITE}} "
    PS1+="${P_USER}\u${P_WHITE}@${P_HOST}\h "
    PS1+="${P_YELLOW}${P_PWD} "
    PS1+="$(parse_git) "
    PS1+="${P_EXIT}\n"
    PS1+="${P_YELLOW}➤  ${P_RESET}"
}

# 初始化颜色和提示符
_setup_colors
PROMPT_COMMAND=bash_prompt_command
