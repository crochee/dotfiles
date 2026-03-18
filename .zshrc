# If not running interactively, don't do anything
[[ -z $PS1 ]] && return

# Resolve DOTFILES_DIR (assuming ~/.dotfiles on systems without readlink and/or $0)
if [[ -n ${0} && -x readlink ]]; then
    DOTFILES_DIR="${PWD}/$(dirname "$(readlink -n "${0}")")"
elif [ -d "$HOME/.dotfiles" ]; then
    DOTFILES_DIR="$HOME/.dotfiles"
else
    echo "Unable to find dotfiles, exiting."
    return
fi

export DOTFILES_DIR

# set workspace
mkdir -p "$HOME/workspace"
mkdir -p "$HOME/.local/bin"
export WORKSPACE=$HOME/workspace

# Make utilities available
PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)
for DOTFILE in "$DOTFILES_DIR/system"/{.alias,.env,*.sh,*.zsh,*.bash}; do
    # shellcheck disable=SC1090
    source "$DOTFILE" 2>/dev/null

done

# Wrap up

unset DOTFILE

# Remove duplicates (preserving prepended items)
# Source: http://unix.stackexchange.com/a/40755

# Mac specific configuration

# Homebrew path
if [ -d "/opt/homebrew/bin" ]; then
    PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
    PATH="/usr/local/bin:$PATH"
fi

PATH=$(echo -n "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')

export PATH

# Mac specific aliases and functions
if [[ "$(uname)" == "Darwin" ]]; then
    # Aliases for Mac specific commands
    alias ls="ls -la"
    alias finder="open"
    
    # Function to show hidden files in Finder
    showhidden() {
        defaults write com.apple.finder AppleShowAllFiles YES
        killall Finder
    }
    
    # Function to hide hidden files in Finder
    hidehidden() {
        defaults write com.apple.finder AppleShowAllFiles NO
        killall Finder
    }
fi

# Zsh specific configuration

# Enable colored output
autoload -U colors && colors

# Set prompt (similar to prompt.sh)
autoload -Uz vcs_info

# 设置颜色
zstyle ':vcs_info:*' formats '%F{yellow}(%s %b%F{yellow})%f'
zstyle ':vcs_info:*' actionformats '%F{red}(%s %b|%a%F{red})%f'

# Git 信息
parse_git() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi
    
    local git_ref
    git_ref=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -z "$git_ref" ]]; then
        git_ref=$(git describe --tags --exact-match HEAD 2>/dev/null)
        [[ -z "$git_ref" ]] && return
    fi
    
    local git_dirty=""
    if [[ -n $(git status --porcelain --ignore-submodules -uno 2>/dev/null) ]]; then
        git_dirty="%F{red}*%f"
    fi
    
    local git_commit=""
    local upstream_branch=$(git rev-parse --symbolic-full-name --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream_branch" ]]; then
        local commits_behind=$(git rev-list --count --max-count=100 HEAD..@{u} 2>/dev/null || echo 0)
        local commits_ahead=$(git rev-list --max-count=100 @{u}..HEAD 2>/dev/null || echo 0)
        
        [[ $commits_behind -gt 0 ]] && git_commit+="%F{cyan}↓$commits_behind%f"
        [[ $commits_ahead -gt 0 ]] && git_commit+="%F{cyan}↑$commits_ahead%f"
        [[ -n "$git_commit" ]] && git_commit=" $git_commit"
    fi
    
    local git_stash=""
    if [[ -f "$(git rev-parse --git-dir 2>/dev/null)/refs/stash" ]]; then
        git_stash="%F{blue}⚑%f"
    fi
    
    echo "%F{yellow}($git_ref${git_commit}${git_dirty}${git_stash}%F{yellow})%f"
}

# 智能路径截断
truncate_path() {
    local max_length=35
    local path="${PWD/#$HOME/~}"
    
    if [[ ${#path} -le $max_length ]]; then
        echo "$path"
        return
    fi
    
    local truncated=".."
    local remaining=$((max_length - 2))
    echo "${path: -$remaining}"
}

# 主提示符
set_prompt() {
    local exit_code=$?
    local p_exit=""
    
    if [[ $exit_code != 0 ]]; then
        p_exit="%F{red}✘ %f"
    fi
    
    local time_str="%F{yellow}$(date +"%y-%m-%d %H:%M:%S")%f"
    local user_host="%F{magenta}%n%f@%F{green}%m%f"
    local path="%F{yellow}$(truncate_path)%f"
    local git_info="$(parse_git)"
    
    PROMPT="${p_exit}${time_str} ${user_host} ${path} ${git_info}
%F{yellow}➤  %f"
}

# 设置 precmd 函数
precmd() {
    vcs_info
    set_prompt
}

# Enable history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Enable completion
autoload -U compinit
compinit

# Enable correction
setopt correct_all

# Enable globbing
setopt extended_glob

# Enable auto cd
setopt auto_cd

# Enable auto pushd
setopt auto_pushd

# Enable prompt substitution
setopt prompt_subst

# Source zsh plugins if any
if [ -d "$HOME/.oh-my-zsh" ]; then
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi

# Source local zshrc if it exists
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi