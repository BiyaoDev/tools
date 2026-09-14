#!/bin/bash
# bbr-enable.sh - 启用 TCP BBR 拥塞控制算法（Debian 系列通用）
# 配置写入：/etc/sysctl.d/99-sysctl.conf
# 前置检测：内核支持、模块加载、当前运行状态

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

CONF_FILE="/etc/sysctl.d/99-sysctl.conf"

# 1. 检测内核是否支持 BBR
if ! modprobe -n tcp_bbr &>/dev/null; then
    echo "❌ 当前内核不支持 BBR 拥塞控制算法"
    echo "Debian 13 默认内核 6.x 已原生支持，如为自定义内核请重新编译"
    exit 1
fi

# 2. 加载 tcp_bbr 内核模块（如未加载）
if ! lsmod | grep -q "^tcp_bbr"; then
    if modprobe tcp_bbr; then
        echo "ℹ️  已加载 tcp_bbr 内核模块"
    else
        echo "❌ 加载 tcp_bbr 模块失败"
        exit 1
    fi
fi

# 3. 检测当前是否已启用 BBR
CURRENT_CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
if [ "$CURRENT_CC" = "bbr" ]; then
    echo "✅ BBR 拥塞控制已处于启用状态，无需重复配置"
    echo "当前拥塞控制算法：$CURRENT_CC"
    echo "队列调度算法：$(sysctl -n net.core.default_qdisc)"
    exit 0
fi

# 4. 确保配置文件存在，清理旧的相关配置（避免重复/冲突）
touch "$CONF_FILE"
sed -i '/^net.core.default_qdisc/d' "$CONF_FILE"
sed -i '/^net.ipv4.tcp_congestion_control/d' "$CONF_FILE"

# 5. 写入 BBR 配置（fq 队列调度为 BBR 推荐配套配置）
cat >> "$CONF_FILE" <<EOF

# TCP BBR 拥塞控制
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

echo "✅ 已写入配置到 $CONF_FILE"

# 6. 应用配置并验证
if sysctl -p "$CONF_FILE" >/dev/null 2>&1; then
    AFTER_CC=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [ "$AFTER_CC" = "bbr" ]; then
        echo -e "\n===== 配置生效成功 ====="
        echo "拥塞控制算法：$AFTER_CC"
        echo "队列调度算法：$(sysctl -n net.core.default_qdisc)"
    else
        echo "❌ 配置应用失败，当前算法：$AFTER_CC"
        exit 1
    fi
else
    echo "❌ 执行 sysctl -p 失败，请检查配置文件语法"
    exit 1
fi
