## Prompt

bash_prompt_command() {
    local USER_SYMBOL="\u"
    local HOST_SYMBOL="\h"
    local ESC_OPEN="\["
    local ESC_CLOSE="\]"
    local RESET=""
    if tput setaf >/dev/null 2>&1; then
        _setaf() { tput setaf "$1"; }
        RESET="${ESC_OPEN}$({ tput sgr0 || tput me; } 2>/dev/null)${ESC_CLOSE}"
    else
        # Fallback
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

    # Expose the variables we need in prompt command
    P_USER=${BRIGHT_VIOLET}${USER_SYMBOL}
    P_HOST=${BRIGHT_GREEN}${HOST_SYMBOL}
    P_WHITE=${WHITE}
    P_YELLOW=${YELLOW}
    P_RED=${RED}
    P_RESET=${RESET}

    local EXIT_CODE=$?
    local P_EXIT=""
    local MAXLENGTH=35
    local TRUNC_SYMBOL=".."
    local DIR=${PWD##*/}
    local P_PWD=${PWD/#$HOME/\~}

    MAXLENGTH=$(((MAXLENGTH < ${#DIR}) ? ${#DIR} : MAXLENGTH))

    local OFFSET=$((${#P_PWD} - MAXLENGTH))

    if [ ${OFFSET} -gt "0" ]; then
        P_PWD=${P_PWD:$OFFSET:$MAXLENGTH}
        P_PWD=${TRUNC_SYMBOL}/${P_PWD#*/}
    fi

    # Update terminal title
    if [[ $TERM == xterm* ]]; then
        echo -ne "\033]0;${P_PWD}\007"
    fi
    # Parse Git branch name
    P_GIT=$(parse_git)

    # Exit code
    if [[ $EXIT_CODE != 0 ]]; then
        P_EXIT+="${P_RED}✘ "
    fi

    PS1="${P_WHITE}{${P_YELLOW}$(date +"%y-%m-%d %H:%M:%S")${P_WHITE}} ${P_USER}${P_WHITE}@${P_HOST} ${P_YELLOW}${P_PWD} ${P_GIT} ${P_EXIT}\n${P_YELLOW}➤  ${P_RESET}"
}

parse_git() {
    # 获取 Git 分支名
    local git_branch=""
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ "$git_branch" == "" ]; then
        return
    fi
    # 初始化 git_dirty 变量
    # 检查是否有未提交的改动
    local git_dirty="✓"
    if [[ -n $(git status --porcelain) ]]; then
        git_dirty="${P_RED}*"
    fi
    # 获取与上游分支相差的 commit 数量
    local git_commit=""
    if [[ -n "$(git rev-parse --symbolic-full-name --abbrev-ref @{u} 2>/dev/null)" ]]; then
        local commits_behind=""
        local commits_ahead=""
        commits_behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
        commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
        if [[ $commits_behind -gt 0 ]]; then
            git_commit+="↓$commits_behind"
        fi
        if [[ $commits_ahead -gt 0 ]]; then
            git_commit+="↑$commits_ahead"
        fi
    fi
    if [[ $git_commit != "" ]]; then
        git_commit="${git_commit} "
    fi
    echo "${P_YELLOW}(${git_branch} ${git_commit}${git_dirty}${P_YELLOW})"
}

PROMPT_COMMAND=bash_prompt_command
