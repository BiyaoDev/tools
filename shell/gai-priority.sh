#!/bin/bash
# gai-priority.sh - Enable IPv4 precedence in /etc/gai.conf (uncomment if exists)
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Must run as root"
    exit 1
fi

CONF="/etc/gai.conf"
LINE="precedence ::ffff:0:0/96 100"
COMMENT_LINE="#${LINE}"

# 如果存在注释的那一行，取消注释
if grep -q "^${COMMENT_LINE}" "$CONF"; then
    sed -i "s/^${COMMENT_LINE}/${LINE}/" "$CONF"
    echo "✅ Uncommented IPv4 precedence line."
elif grep -q "^${LINE}" "$CONF"; then
    echo "✅ Already enabled."
else
    echo "$LINE" >> "$CONF"
    echo "✅ Added IPv4 precedence line."
fi
