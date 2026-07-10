#!/bin/bash
# 服务存放目录
SERVER_DIR="/root/nianServer"
# 日志存放
LOG_DIR="/root/nianServer/logs"
mkdir -p $LOG_DIR

# 启动 signaling_server 后台运行，日志输出
nohup lua5.1 ${SERVER_DIR}/signaling_server.lua > ${LOG_DIR}/signaling.log 2>&1 &
echo "启动完成：signaling_server  PID=$!"

# 启动 stun_server 后台运行
nohup lua5.1 ${SERVER_DIR}/stun_server.lua > ${LOG_DIR}/stun.log 2>&1 &
echo "启动完成：stun_server      PID=$!"

echo "全部服务已后台常驻，断开SSH不会停止"
echo "查看日志：tail -f /root/nianServer/logs/signaling.log"
echo "查看日志：tail -f /root/nianServer/logs/stun.log"