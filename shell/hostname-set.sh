#!/bin/bash
# hostname-set.sh - 修改系统主机名并同步更新 /etc/hosts 映射
# 支持两种用法：命令行传参 或 交互输入新主机名

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# 获取新主机名：优先取命令行参数，无参数则交互提示输入
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

# 1. 通过 hostnamectl 设置静态主机名
hostnamectl set-hostname "$NEW_HOSTNAME"
echo "✅ 主机名已设置为: $NEW_HOSTNAME"

# 2. 向 /etc/hosts 添加 127.0.1.1 映射，整行匹配避免重复追加
HOSTS_LINE="127.0.1.1 $NEW_HOSTNAME"
if grep -qxF "$HOSTS_LINE" /etc/hosts; then
    echo "ℹ️ /etc/hosts 中已存在该映射，无需重复添加"
else
    echo "$HOSTS_LINE" >> /etc/hosts
    echo "✅ 已向 /etc/hosts 添加映射: $HOSTS_LINE"
fi

# 3. 输出验证结果
echo -e "\n===== 验证结果 ====="
echo "当前主机名：$(hostname)"
echo -e "\n/etc/hosts 中 127.0.1.1 相关行："
grep "127.0.1.1" /etc/hosts
