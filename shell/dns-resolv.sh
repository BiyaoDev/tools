#!/bin/bash
# dns-resolv.sh - 配置 DNS 服务器并锁定 /etc/resolv.conf 防止被覆盖
# DNS：Cloudflare + Google 公共 DNS（含 IPv6）

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

RESOLV="/etc/resolv.conf"

# 检查 chattr 命令是否存在
if ! command -v chattr &> /dev/null; then
    echo "⚠️  系统未安装 chattr，无法锁定文件，仅配置 DNS"
    LOCK_SUPPORT=0
else
    LOCK_SUPPORT=1
fi

# 若文件存在且有不可变属性，先解锁
if [ -f "$RESOLV" ] && [ "$LOCK_SUPPORT" -eq 1 ]; then
    if lsattr "$RESOLV" 2>/dev/null | grep -q 'i'; then
        chattr -i "$RESOLV"
        echo "ℹ️  已解除 resolv.conf 的不可变锁"
    fi
fi

# 写入 DNS 配置
cat > "$RESOLV" <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 2606:4700:4700::1111
nameserver 2001:4860:4860::8888
EOF

# 校验写入结果
if grep -q "nameserver 1.1.1.1" "$RESOLV"; then
    echo "✅ DNS 配置写入成功"
else
    echo "❌ DNS 配置写入失败，请检查文件权限"
    exit 1
fi

# 重新加锁
if [ "$LOCK_SUPPORT" -eq 1 ]; then
    chattr +i "$RESOLV"
    if lsattr "$RESOLV" | grep -q 'i'; then
        echo "✅ 已重新锁定 /etc/resolv.conf，防止被系统覆盖"
    else
        echo "⚠️  文件锁定失败，请手动执行：chattr +i $RESOLV"
    fi
fi

echo -e "\n当前 DNS 配置："
cat "$RESOLV"
