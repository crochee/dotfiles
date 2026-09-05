# system/alias.fish —— fish 版别名与函数
#
# 加载方：fish/config.fish 第 2 段

# bash 的 `alias rl="exec $SHELL"` 在 fish 里换成 function：
# - 显式 exec 当前 fish 二进制（-l 保留 login 语义，重新 source config.fish）
# - 不依赖 $SHELL：父进程可能未设 / 被设成 bash（chsh 未生效时），exec $SHELL 会掉回 bash
function rl --description '重载当前 fish 配置'
    set -l _rl_fish (command -v fish)
    or begin; echo "rl: fish not found" >&2; return 1; end
    # exec 替换当前进程；用 env(1) 把 SHELL 传给子 fish，
    # 否则子进程从父继承 unset $SHELL（典型 omp/sub-shell 场景）。
    exec env SHELL=$_rl_fish $_rl_fish -l
end

# 基础
alias c='clear'
command -sq nvim; and alias v='nvim'
command -sq bat;  and alias cat='bat'

alias wk="cd $HOME/workspace"
alias dot="cd $HOME/.dotfiles"

# ls
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# 搜索
alias rg='rg --hidden --smart-case'

# cd（`cd -` 在 fish 里是内置支持，无需别名）
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 磁盘
alias df='df -h'
alias du='du -h'

# git
alias ga='git add'
alias gm='git commit'
alias gl='git pull'
alias gs='git status'
alias gc='git clone --recursive'
alias gr='git rebase -i'

# git 函数
function gph
    test (count $argv) -eq 1; and command git push origin "HEAD:$argv[1]"
end
function gphf
    test (count $argv) -eq 1; and command git push origin "HEAD:$argv[1]" -f
end

# 文件
alias mkdir='mkdir -p'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias rr='rm -rf'

# 解压
function extract --description '解压常见归档'
    if test -f "$argv[1]"
        switch "$argv[1]"
            case '*.tar.gz' '*.tgz'
                tar zxvf "$argv[1]"
            case '*.tar.bz2' '*.tbz'
                tar jxvf "$argv[1]"
            case '*.tar.xz' '*.txz'
                tar Jxvf "$argv[1]"
            case '*.tar'
                tar xvf "$argv[1]"
            case '*.zip'
                unzip "$argv[1]"
            case '*.rar'
                unrar x "$argv[1]"
            case '*.7z'
                7z x "$argv[1]"
            case '*'
                echo "Unknown archive type: $argv[1]"
        end
    else
        echo "File not found: $argv[1]"
    end
end

# 建目录并进入
function mcd --description 'mkdir -p && cd'
    mkdir -p "$argv[1]"; and cd "$argv[1]"
end

# docker（仅装时定义）
command -sq docker; and alias dive='docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/wagoodman/dive:latest'
command -sq docker; and alias slim='docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock dslim/slim:latest'
command -sq docker; and alias trivy='docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest'
