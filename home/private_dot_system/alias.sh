# ~/.system/alias.sh — sourced by .bashrc / .zshrc.
# shellcheck shell=bash

rl() {
    if [ -n "${BASH_VERSION:-}" ]; then exec bash -l
    else exec zsh -l
    fi
}

alias v='nvim'
alias cat='bat'
alias wk='cd "$WORKSPACE"'
alias c='clear'
alias dot='cd "$DOTFILES_DIR"'

case "$(uname -s)" in
    Darwin) alias ls='ls -G' ;;
    *)      alias ls='ls --color=auto' ;;
esac
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias rg="rg --hidden --smart-case --glob '!.git'"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias df='df -h'
alias du='du -h'

alias ga='git add'
alias gm='git commit'
alias gl='git pull'
alias gs='git status'
alias gc='git clone --recursive'
alias gr='git rebase -i'
gph()  { [ $# -eq 1 ] && git push origin "HEAD:$1"; }
gphf() { [ $# -eq 1 ] && git push origin "HEAD:$1" -f; }

alias kc='kubectl'
alias k='kubectl'
alias kpods='kubectl get pods -A --field-selector=status.phase!=Running'
alias mkdir='mkdir -p'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias rr='rm -rf'

extract() {
    if [ ! -f "$1" ]; then echo "File not found: $1" >&2; return 1; fi
    case "$1" in
        *.tar.gz|*.tgz)  tar zxvf "$1" ;;
        *.tar.bz2|*.tbz) tar jxvf "$1" ;;
        *.tar.xz|*.txz)  tar Jxvf "$1" ;;
        *.tar)           tar xvf  "$1" ;;
        *.zip|*.7z)      7zz x   "$1" ;;
        *) echo "Unknown archive type: $1" >&2; return 1 ;;
    esac
}

mcd() { mkdir -p "$1" && cd "$1" || return; }

alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
# Honor $DOCKER_HOST (colima sets its own socket); default /var/run/docker.sock.
_docker_socket() {
    case "${DOCKER_HOST:-}" in
        unix://*) printf '%s' "${DOCKER_HOST#unix://}" ;;
        *)        printf '%s' "/var/run/docker.sock" ;;
    esac
}
_docker_with_socket() { docker run --rm -ti -v "$(_docker_socket):/var/run/docker.sock" "$@"; }
alias dive='_docker_with_socket ghcr.io/wagoodman/dive:latest'
alias slim='_docker_with_socket dslim/slim:latest'
alias trivy='_docker_with_socket aquasec/trivy:latest'

# diff then apply; --exclude=scripts keeps run_after hook bodies out of the diff.
da() {
    _da_diff="$(chezmoi diff --exclude=scripts --)"
    if [ -z "$_da_diff" ]; then
        printf 'no changes\n'
        return 0
    fi
    printf '%s\n' "$_da_diff"
    printf 'apply? [y/N] '
    IFS= read -r _da_reply || { unset _da_diff; return 130; }
    case "$_da_reply" in
        y|Y|yes|YES) ;;
        *) printf 'aborted\n'; unset _da_diff _da_reply; return 0 ;;
    esac
    chezmoi apply --
    unset _da_diff _da_reply
}

daf() {
    OMP_CONFIG_FORCE=1 chezmoi apply --force --
}