#!/bin/bash
# 设置DNS：Cloudflare + Google DNS，并锁定resolv.conf不可修改

# 必须root执行
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# 如果文件有不可变属性，先取消
if lsattr /etc/resolv.conf | grep -q '----i'; then
    chattr -i /etc/resolv.conf
fi

# 删除旧文件，写入DNS配置
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 2606:4700:4700::1111
nameserver 2001:4860:4860::8888
EOF

# 重新加上不可变锁
chattr +i /etc/resolv.conf

echo "✅ DNS配置写入完成，并已锁定 /etc/resolv.conf"
echo "当前resolv.conf内容："
cat /etc/resolv.conf
