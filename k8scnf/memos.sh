docker run -itd --name memos -p 5230:5230  -v ~/.memos:/var/opt/memos --restart=always  neosmemo/memos:stable

http://localhost:5230
