#!/bin/bash

curl 'https://glados.rocks/api/user/checkin' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'authorization: 47898876190570387765234016300546-1440-2560' \
  -H 'content-type: application/json;charset=UTF-8' \
  -b '_ga=GA1.1.1845477581.1736836607; _ga_CZFVKMNT9J=GS1.1.1736836606.1.1.1736836667.0.0.0; __stripe_mid=ee74b9b0-4493-4131-897f-ed2954f32018bc6a3b; koa:sess=eyJ1c2VySWQiOjI0NjcwMSwiX2V4cGlyZSI6MTc3MjQxNDIxOTM5MywiX21heEFnZSI6MjU5MjAwMDAwMDB9; koa:sess.sig=u5aOKcZcLV6mmf152bEXUTjxgno; __stripe_sid=eddeafce-c9c2-4a30-950e-1c70c74c7f17af5ef1' \
  -H 'origin: https://glados.rocks' \
  -H 'priority: u=1, i' \
  -H 'sec-ch-ua: "Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' \
  --data-raw '{"token":"glados.one"}'
