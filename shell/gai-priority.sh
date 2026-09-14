#!/bin/bash
# gai-priority.sh - 启用 /etc/gai.conf 中 IPv4 解析优先（存在注释行则自动取消注释）
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

CONF="/etc/gai.conf"
LINE="precedence ::ffff:0:0/96 100"
COMMENT_LINE="#${LINE}"

# 如果存在注释的那一行，取消注释
if grep -q "^${COMMENT_LINE}" "$CONF"; then
    sed -i "s/^${COMMENT_LINE}/${LINE}/" "$CONF"
    echo "✅ 已取消注释，IPv4 解析优先已启用"
elif grep -q "^${LINE}" "$CONF"; then
    echo "✅ IPv4 解析优先已处于启用状态"
else
    echo "$LINE" >> "$CONF"
    echo "✅ 已添加配置，IPv4 解析优先已启用"
fi
