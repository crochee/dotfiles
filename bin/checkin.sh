#!/bin/bash

curl 'https://glados.rocks/api/user/checkin' \
  -H 'authority: glados.rocks' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'authorization: 2255308630345569164574338915520-720-1280' \
  -H 'content-type: application/json;charset=UTF-8' \
  -H 'cookie: __stripe_mid=111d99f1-d6d0-4857-b1a8-62c524c43ff41c3bb6; koa:sess=eyJ1c2VySWQiOjI0NjcwMSwiX2V4cGlyZSI6MTcxOTE5Nzk4NjQyMiwiX21heEFnZSI6MjU5MjAwMDAwMDB9; koa:sess.sig=eEUaXNLSfhN6w-PxyyRVQ585FOA; _gid=GA1.2.125486497.1704677444; _gat_gtag_UA_104464600_2=1; _ga=GA1.1.145902243.1670400438; _ga_CZFVKMNT9J=GS1.1.1704849381.89.1.1704849398.0.0.0' \
  -H 'origin: https://glados.rocks' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  --data-raw '{"token":"glados.one"}' \
  --compressed
