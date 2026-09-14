#!/bin/bash
# gai-priority.sh - 配置 /etc/gai.conf 使域名解析优先使用 IPv4

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

CONF="/etc/gai.conf"
LINE="precedence ::ffff:0:0/96 100"
# 转义特殊字符用于正则匹配
LINE_ESCAPED="${LINE//\./\\.}"
COMMENT_PATTERN="^[[:space:]]*#[[:space:]]*${LINE_ESCAPED}"
ACTIVE_PATTERN="^[[:space:]]*${LINE_ESCAPED}"

# 检查配置文件是否存在
if [ ! -f "$CONF" ]; then
    echo "ℹ️ 配置文件 $CONF 不存在，正在创建"
    touch "$CONF"
fi

# 检查是否已存在生效配置
if grep -qE "$ACTIVE_PATTERN" "$CONF"; then
    echo "✅ IPv4 解析优先已处于启用状态，无需重复配置"
    exit 0
fi

# 检查是否存在注释行，有则取消注释
if grep -qE "$COMMENT_PATTERN" "$CONF"; then
    sed -i -E "s/${COMMENT_PATTERN}/${LINE}/" "$CONF"
    if grep -qE "$ACTIVE_PATTERN" "$CONF"; then
        echo "✅ 已取消注释，IPv4 解析优先已启用"
    else
        echo "❌ 配置修改失败，请手动检查 $CONF"
        exit 1
    fi
else
    # 无对应行，追加配置
    echo "$LINE" >> "$CONF"
    if grep -qE "$ACTIVE_PATTERN" "$CONF"; then
        echo "✅ 已添加配置，IPv4 解析优先已启用"
    else
        echo "❌ 配置写入失败，请检查文件权限"
        exit 1
    fi
fi

echo -e "\n💡 提示：部分系统需重启网络后完全生效，可执行：systemctl restart systemd-resolved"
