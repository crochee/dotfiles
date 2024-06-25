#!/bin/bash

curl 'https://glados.rocks/api/user/checkin' \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: zh-CN,zh;q=0.9' \
    -H 'authorization: 2255308630345569164574338915520-720-1280' \
    -H 'content-type: application/json;charset=UTF-8' \
    -H 'cookie: koa:sess=eyJ1c2VySWQiOjI0NjcwMSwiX2V4cGlyZSI6MTczNTQ0MTcxNTk2OCwiX21heEFnZSI6MjU5MjAwMDAwMDB9; koa:sess.sig=mnT8_Pb-ej9LD1SiEaIhGzrbQfc; _ga=GA1.1.1558106892.1709521685; _ga_CZFVKMNT9J=GS1.1.1709521684.1.1.1709523258.0.0.0' \
    -H 'origin: https://glados.rocks' \
    -H 'priority: u=1, i' \
    -H 'sec-ch-ua: "Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-origin' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' \
    --data-raw '{"token":"glados.one"}'
