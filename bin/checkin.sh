#!/bin/bash
# GLaDOS 签到。cookie 直接内嵌在下面的 COOKIE 里 — cron 环境没有交互 shell
# 的任何配置, 脚本自身就是唯一数据源, 不读环境变量、不读 ~/.system/env.sh。
# 换 cookie: 浏览器登录后复制 (2026-09 起域名 glados.rocks, 旧 koa:sess 作废),
# 形如 gld:sess=xxx; gld:sess.sig=yyy。
# cron 示例：0 9 * * * "$HOME/.dotfiles/bin/checkin.sh" >> "$HOME/.cache/glados.log" 2>&1
set -u

# shellcheck disable=SC2034  # COOKIE 在下方 curl -b 使用
COOKIE='gld:sess=gld_3cae9af88583004b4fc0456372ac7ca04c952c0f8a37e904; gld:sess.sig=BiFsjuk11-Q-mER6rAKXHh-aM28'
case "$COOKIE" in
    'gld:sess=xxx; gld:sess.sig=yyy'|'')
        echo '先把 bin/checkin.sh 顶部的 COOKIE 换成真实 cookie'; exit 1 ;;
esac

max_retries=3
retry_delay=5

echo "开始执行签到请求，最多重试 $max_retries 次..."

for ((i = 1; i <= max_retries; i++)); do
    echo "第 $i 次尝试..."

    if curl -sS 'https://glados.rocks/api/user/checkin' \
        -H 'accept: application/json, text/plain, */*' \
        -H 'accept-language: zh-CN,zh;q=0.9' \
        -H 'content-type: application/json;charset=UTF-8' \
        -H 'origin: https://glados.rocks' \
        -H 'priority: u=1, i' \
        -H 'sec-ch-ua: "Chromium";v="152", "Not?A_Brand";v="24", "Google Chrome";v="152"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: same-origin' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36' \
        -b "$COOKIE" \
        --data-raw '{"token":"glados.rocks"}'; then
        echo "签到请求成功！"
        exit 0
    fi

    if [ "$i" -lt "$max_retries" ]; then
        echo "请求失败，$retry_delay 秒后重试..."
        sleep "$retry_delay"
    fi
done

echo "所有重试均失败，签到请求未成功。"
exit 1
