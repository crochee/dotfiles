#!/usr/bin/env bash

unset COLUMNS
set -e


SCRIPT_PATH=$(dirname $(dirname "$BASH_SOURCE"))

beforedate=`date -d$1 +'%Y-%m-%d'`
afterdate=`date -d$1'-7 day' +'%Y-%m-%d'`
echo "afterdate: $afterdate  beforedate: $beforedate"

DCS=~/workspace/project/dcs
cd $DCS

function gitlog()
{
    local cur_branch=`git branch|awk '{print $2}'|xargs echo`
    if [[ $1 != $cur_branch ]]; then
        local has_branch=`git branch|grep $1`
        if [[ -z $has_branch ]]; then
            local has_remote_branch=`git branch -r|grep $1`
            if [[ -z $has_remote_branch ]]; then
                return;
            else
                git checkout -b $1  origin/$1
                [[ $? -ne 0 ]] &&  return;
            fi
        else
            git checkout $1
            [[ $? -ne 0 ]] &&  return;
        fi
    fi
    git pull
    git log --after="$afterdate" --before="$beforedate" --author="crochee"|cat
}

dirs=`ls -d */`
for  i in $dirs
do
    echo "$i"
    cd $i
    gitlog $2
    cd $DCS
done

cd $SCRIPT_PATH

unset SCRIPT_PATH DCS
