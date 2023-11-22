#!/usr/bin/env bash

unset COLUMNS
set -e

PWD=$(pwd)

beforedate=$(date -d "$1" +'%Y-%m-%d')
afterdate=$(date -d "$1"'-7 day' +'%Y-%m-%d')
echo "afterdate: $afterdate  beforedate: $beforedate"

PROJECT=~/workspace/project/dcs

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
	if git_checkout "$2"; then
		git log --after="$afterdate" --before="$beforedate" --author="crochee" | cat
	fi
done

cd "$PWD"
unset PWD,PROJECT
