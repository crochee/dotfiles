# 定义颜色和工具函数
_setup_colors() {
    local ESC_OPEN="\["
    local ESC_CLOSE="\]"
    local RESET=""

    if tput setaf >/dev/null 2>&1; then
        _setaf() { tput setaf "$1"; }
        RESET="${ESC_OPEN}$({ tput sgr0 || tput me; } 2>/dev/null)${ESC_CLOSE}"
    else
        # Fallback for systems without tput
        _setaf() { printf "\033[0;%sm" $(($1 + 30)); }
        RESET="\033[m"
        ESC_OPEN=""
        ESC_CLOSE=""
    fi

    # Normal colors
    RED="${ESC_OPEN}$(_setaf 1)${ESC_CLOSE}"
    YELLOW="${ESC_OPEN}$(_setaf 3)${ESC_CLOSE}"
    WHITE="${ESC_OPEN}$(_setaf 7)${ESC_CLOSE}"

    # Bright colors
    BRIGHT_GREEN="${ESC_OPEN}$(_setaf 10)${ESC_CLOSE}"
    BRIGHT_VIOLET="${ESC_OPEN}$(_setaf 13)${ESC_CLOSE}"

    # Expose colors for prompt
    P_USER=${BRIGHT_VIOLET}
    P_HOST=${BRIGHT_GREEN}
    P_WHITE=${WHITE}
    P_YELLOW=${YELLOW}
    P_RED=${RED}
    P_RESET=${RESET}
}

# 解析 Git 信息
parse_git() {
    # 检查是否在 Git 仓库中
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    # 获取 Git 分支名或标签名
    local git_ref=""
    git_ref=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$git_ref" ]; then
        git_ref=$(git describe --tags --exact-match HEAD 2>/dev/null)
        if [ -z "$git_ref" ]; then
            return
        fi
    fi

    # 检查是否有未提交的改动
    local git_dirty="✓"
    if [[ -n $(git status --porcelain --ignore-submodules 2>/dev/null) ]]; then
        git_dirty="${P_RED}*"
    fi

    # 获取与上游分支相差的 commit 数量
    local git_commit=""
    local upstream_branch=$(git rev-parse --symbolic-full-name --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream_branch" ]]; then
        local commits_behind=$(git rev-list --count --max-count=100 HEAD..@{u} 2>/dev/null)
        local commits_ahead=$(git rev-list --count --max-count=100 @{u}..HEAD 2>/dev/null)
        if [[ $commits_behind -gt 0 ]]; then
            git_commit+="↓$commits_behind"
        fi
        if [[ $commits_ahead -gt 0 ]]; then
            git_commit+="↑$commits_ahead"
        fi
    fi
    if [[ -n "$git_commit" ]]; then
        git_commit="${git_commit} "
    fi

    # 检查是否有 stash
    local git_stash=""
    if [[ -n $(git stash list 2>/dev/null) ]]; then
        git_stash="${P_BLUE}⚑"
    fi

    # 检查是否处于 rebase 或 merge 状态
    local git_state=""
    if [[ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" || -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]]; then
        git_state="${P_RED}↦"
    elif [[ -f "$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)" ]]; then
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

    # 截断过长的路径
    if [[ ${#P_PWD} -gt $MAXLENGTH ]]; then
        P_PWD="${TRUNC_SYMBOL}/${P_PWD: -$((MAXLENGTH - ${#TRUNC_SYMBOL} - 1))}"
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
    PS1="${P_WHITE}{${P_YELLOW}$(date +"%y-%m-%d %H:%M:%S")${P_WHITE}} ${P_USER}\u${P_WHITE}@${P_HOST}\h ${P_YELLOW}${P_PWD} $(parse_git) ${P_EXIT}\n${P_YELLOW}➤  ${P_RESET}"
}

# 初始化颜色和提示符
_setup_colors
PROMPT_COMMAND=bash_prompt_command
