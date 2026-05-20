#!/bin/bash

# 出现域名无法解析的情况则进行重试
max_retries=3
retry_delay=5

echo "开始执行签到请求，最多重试 $max_retries 次..."

for ((i=1; i<=$max_retries; i++)); do
  echo "第 $i 次尝试..."
  
  curl 'https://glados.cloud/api/user/checkin' \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: zh-CN,zh;q=0.9' \
    -H 'content-type: application/json;charset=UTF-8' \
    -b 'koa:sess=eyJ1c2VySWQiOjI0NjcwMSwiX2V4cGlyZSI6MTc5NDcyNDE1NTY1NiwiX21heEFnZSI6MjU5MjAwMDAwMDB9; koa:sess.sig=qpFQ-ureSoeZQUgr42Dep6Vp70E' \
    -H 'origin: https://glados.cloud' \
    -H 'priority: u=1, i' \
    -H 'sec-ch-ua: "Google Chrome";v="143", "Chromium";v="143", "Not A(Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-origin' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36' \
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
