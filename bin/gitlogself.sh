#!/usr/bin/env bash

unset COLUMNS
set -e

PWD=$(pwd)

PROJECT=~/workspace/dcs

function git_checkout() {
    cur_branch=$(git branch --show-current)
    if [[ "$1" != "$cur_branch" ]]; then
        has_branch=$(git branch --list "$1")
        if [[ -z "$has_branch" ]]; then
            has_remote_branch=$(git branch -r | grep "$1")
            if [[ -z "$has_remote_branch" ]]; then
                return 1
            fi

            git fetch
            git checkout -b "$1" "origin/$1"
            return
        fi

        if ! git checkout "$1"; then
            return 1
        fi
    fi
    git pull
}

dirs=$(find "$PROJECT" -maxdepth 1 -type d ! -wholename "$PROJECT")
for i in $dirs; do
    echo "$i"
    cd "$i"
    if git_checkout "$1" && [[ -n "$2" ]]; then
        beforedate=$(date -d "$2" +'%Y-%m-%d')
        afterdate=$(date -d "$2"'-7 day' +'%Y-%m-%d')
        echo "afterdate: $afterdate  beforedate: $beforedate"
        git log --after="$afterdate" --before="$beforedate" --author="crochee" | cat
    fi
done

cd "$PWD"
unset PWD,PROJECT
