#!/bin/bash
# GLaDOS 签到。cookie 保存在 system/.env.local 的 GLADOS_COOKIE（gitignored），
# 形如：koa:sess=xxx; koa:sess.sig=yyy
set -u

COOKIE="${GLADOS_COOKIE:-}"
[ -n "$COOKIE" ] || { echo "未设置 GLADOS_COOKIE（写入 ~/.dotfiles/system/.env.local）"; exit 1; }

max_retries=3
retry_delay=5

echo "开始执行签到请求，最多重试 $max_retries 次..."

for ((i = 1; i <= max_retries; i++)); do
    echo "第 $i 次尝试..."

    curl -sS 'https://glados.cloud/api/user/checkin' \
        -H 'accept: application/json' \
        -H 'content-type: application/json;charset=UTF-8' \
        -H 'origin: https://glados.cloud' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36' \
        -b "$COOKIE" \
        --data-raw '{"token":"glados.cloud"}'

    if [ $? -eq 0 ]; then
        echo "签到请求成功！"
        exit 0
    fi

    if [ $i -lt $max_retries ]; then
        echo "请求失败，$retry_delay 秒后重试..."
        sleep $retry_delay
    fi
done

echo "所有重试均失败，签到请求未成功。"
exit 1
