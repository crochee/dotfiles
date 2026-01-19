#!/bin/bash

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
