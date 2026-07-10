#!/bin/bash
# 匹配lua5.1运行两个服务的进程并强制关闭
pkill -f "lua5.1 /root/nianServer/signaling_server.lua"
pkill -f "lua5.1 /root/nianServer/stun_server.lua"
echo "所有服务进程已全部终止"