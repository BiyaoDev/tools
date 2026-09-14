#!/bin/bash
# hostname-set.sh - 修改系统主机名并同步更新 /etc/hosts 映射
# 支持：命令行传参 / 交互输入 两种模式

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# 检查 hostnamectl 是否可用
if ! command -v hostnamectl &> /dev/null; then
    echo "❌ 当前系统不支持 hostnamectl，无法使用此脚本"
    exit 1
fi

# 获取新主机名：优先命令行参数，无参数则交互输入
if [ $# -ge 1 ]; then
    NEW_HOSTNAME="$1"
else
    read -p "请输入新主机名: " NEW_HOSTNAME
fi

# 非空校验
if [ -z "$NEW_HOSTNAME" ]; then
    echo "❌ 主机名不能为空"
    exit 1
fi

# 合法性校验：只允许字母、数字、横线、点
if ! [[ "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "❌ 主机名不合法，仅允许字母、数字、横线(-)和点(.)"
    exit 1
fi

# 1. 设置静态主机名
OLD_HOSTNAME="$(hostname 2>/dev/null || echo '')"
hostnamectl set-hostname "$NEW_HOSTNAME"
if [ "$(hostname)" = "$NEW_HOSTNAME" ]; then
    echo "✅ 主机名已设置为: $NEW_HOSTNAME"
else
    echo "❌ 主机名设置失败，请手动检查"
    exit 1
fi

# 2. 更新 /etc/hosts
HOSTS="/etc/hosts"

# 清理旧的 127.0.1.1 主机名映射（如果存在）
if [ -n "$OLD_HOSTNAME" ] && grep -q "127.0.1.1[[:space:]]\+$OLD_HOSTNAME" "$HOSTS"; then
    sed -i "/127.0.1.1[[:space:]]\+$OLD_HOSTNAME/d" "$HOSTS"
    echo "ℹ️  已清理旧主机名映射"
fi

# 添加新的映射，避免重复
HOSTS_LINE="127.0.1.1 $NEW_HOSTNAME"
if grep -qxF "$HOSTS_LINE" "$HOSTS"; then
    echo "ℹ️  /etc/hosts 中已存在该映射，无需重复添加"
else
    echo "$HOSTS_LINE" >> "$HOSTS"
    echo "✅ 已向 /etc/hosts 添加映射: $HOSTS_LINE"
fi

# 3. 输出验证结果
echo -e "\n===== 验证结果 ====="
echo "当前主机名：$(hostname)"
echo -e "\n/etc/hosts 中 127.0.1.1 相关行："
grep "127.0.1.1" "$HOSTS"
