#!/bin/sh
# chezmoi bootstrap. Usage: bash ~/.dotfiles/install/install.sh (no args).
# Refuses any arg: this script unconditionally wipes managed rc + shell init.
# chezmoi resolution: $CHEZMOI → PATH → ~/.local/bin → curl install to ~/.local/bin.
set -e

if [ "$#" -ne 0 ]; then
    echo "usage: bash $0  (no arguments; this is the destructive bootstrap)" >&2
    exit 2
fi

install_chezmoi_user() {
    bin_dir="${HOME}/.local/bin"
    mkdir -p "${bin_dir}"
    if ! command -v curl >/dev/null 2>&1; then
        echo "need curl to install chezmoi" >&2
        exit 1
    fi
    curl -fsLS https://get.chezmoi.io | sh -s -- -b "${bin_dir}"
    printf '%s' "${bin_dir}/chezmoi"
}

if [ -n "${CHEZMOI:-}" ] && [ -x "${CHEZMOI}" ]; then
    chezmoi="${CHEZMOI}"
elif command -v chezmoi >/dev/null 2>&1; then
    chezmoi="$(command -v chezmoi)"
elif [ -x "${HOME}/.local/bin/chezmoi" ]; then
    chezmoi="${HOME}/.local/bin/chezmoi"
else
    chezmoi="$(install_chezmoi_user)"
fi

repo="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

_srcroot="$(sed -n '1p' "${repo}/.chezmoiroot" 2>/dev/null)"
_cv="$("${chezmoi}" --version 2>/dev/null | sed -n 's/.*version v\([0-9]*\)\.\([0-9]*\)\..*/\1 \2/p' | head -1)"
_nv="$(sed -n 's/^\([0-9]*\)\.\([0-9]*\)\..*/\1 \2/p' "${repo}/${_srcroot:-.}/.chezmoiversion" 2>/dev/null | head -1)"
if [ -n "${_cv}" ] && [ -n "${_nv}" ]; then
    # shellcheck disable=SC2086
    set -- ${_cv}; _cmaj=$1; _cmin=$2
    # shellcheck disable=SC2086
    set -- ${_nv}; _nmaj=$1; _nmin=$2
    if [ "${_cmaj}" -lt "${_nmaj}" ] || { [ "${_cmaj}" -eq "${_nmaj}" ] && [ "${_cmin}" -lt "${_nmin}" ]; }; then
        echo "chezmoi ${_cmaj}.${_cmin} older than required ${_nmaj}.${_nmin}; installing current into ~/.local/bin" >&2
        chezmoi="$(install_chezmoi_user)"
    fi
fi

# .chezmoiignore un-manages off-dialect files but doesn't delete them; a dialect flip
# would leave stale rc + shell init. Clear; init --apply regenerates.
for _f in \
    "$HOME/.bashrc" "$HOME/.bash_profile" \
    "$HOME/.zshrc" "$HOME/.zprofile" \
    "$HOME/.system/shell.bash.sh" "$HOME/.system/shell.zsh.sh"; do
    [ -e "$_f" ] || continue
    rm -f "$_f" && echo "reset $_f (re-created by the configured dialect)"
done
unset _f

# omp writes its config without honoring chezmoi edits; force overwrite on bootstrap.
export OMP_CONFIG_FORCE=1

# git identity lives in .chezmoidata/local.yaml (only chezmoi data source for templates;
# [data] in chezmoi.toml would override). New clones lack it (gitignored); create 0600,
# fill missing keys from git config → TTY → blank WARN.
_repo_for_local="${repo}"
_local_yaml="${_repo_for_local}/home/.chezmoidata/local.yaml"
if [ ! -f "${_local_yaml}" ]; then
    ( umask 077 && printf '# .chezmoidata/local.yaml — 本机覆盖 + secrets (gitignored, 0600).\n' >"${_local_yaml}" )
fi
if [ -f "${_local_yaml}" ]; then
    _needs_write=0
    for _k in name email github_user; do
        if ! grep -qE "^${_k}:" "${_local_yaml}" 2>/dev/null; then
            _needs_write=$((_needs_write + 1))
        fi
    done
    if [ "${_needs_write}" -gt 0 ]; then
        _name="" _email="" _github=""
        if command -v git >/dev/null 2>&1; then
            _name=$(git config --global --get --default "" user.name)
            _email=$(git config --global --get --default "" user.email)
            _github=$(git config --global --get --default "" github.user)
        fi
        if [ -t 0 ]; then
            [ -z "${_name}" ]   && { printf 'git user.name: ' >&2;   IFS= read -r _name;   }
            [ -z "${_email}" ]  && { printf 'git user.email: ' >&2;  IFS= read -r _email;  }
            [ -z "${_github}" ] && { printf 'GitHub username (blank to omit): ' >&2; IFS= read -r _github; }
        fi
        _yq() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
        _filled=0
        [ -z "${_name}" ]   || { printf '\nname: "%s"\n'      "$(_yq "${_name}")"   >> "${_local_yaml}"; _filled=$((_filled + 1)); }
        [ -z "${_email}" ]  || { printf 'email: "%s"\n'       "$(_yq "${_email}")"  >> "${_local_yaml}"; _filled=$((_filled + 1)); }
        [ -z "${_github}" ] || { printf 'github_user: "%s"\n' "$(_yq "${_github}")" >> "${_local_yaml}"; _filled=$((_filled + 1)); }
        if [ "${_filled}" -lt "${_needs_write}" ]; then
            printf 'WARN: git identity 缺 %d 键 (name/email/github_user); Fix: 在 %s 显式补.\n' "$((_needs_write - _filled))" "${_local_yaml}" >&2
        fi
    fi
fi
unset _needs_write _name _email _github _local_yaml _repo_for_local

exec "${chezmoi}" init --apply --source "${repo}"