#!/bin/sh
#hostip=$(cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }')
hostip=192.168.1.125
wslip=$(hostname -I | awk '{print $1}')
# 这里填写主机代理的端口
port=7890

set_proxy(){
    export ALL_PROXY="socks5://${hostip}:${port}"
    git config --global http.proxy "http://${hostip}:${port}"
    git config --global https.proxy "http://${hostip}:${port}"
}

unset_proxy(){
    unset ALL_PROXY 
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}

test_setting(){
    echo "Host ip:" ${hostip}
    echo "WSL ip:" ${wslip}
    echo "Current proxy:" $ALL_PROXY
}

case "$1" in
    set)
	set_proxy
	;;
    unset)
	unset_proxy
	;;
    test)
	test_setting
	;;
    *)
	echo "unspported arguments."
	;; 	
esac
