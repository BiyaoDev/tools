#!/bin/bash
# tools-menu.sh - Linux 运维工具合集菜单
# 对应仓库：BiyaoDev/tools/shell 目录

# ========== 配置区 ==========
BASE_URL="https://raw.githubusercontent.com/BiyaoDev/tools/refs/heads/main/shell"
SCRIPTS=(
    "hostname-set.sh"
    "gai-priority.sh"
    "dns-resolv.sh"
    "swap.sh"
)
NAMES=(
    "修改主机名并同步 hosts"
    "设置 IPv4 解析优先"
    "配置 DNS 并锁定 resolv.conf"
    "交换分区添加/删除管理"
)
# ============================

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此工具"
    exit 1
fi

# 执行指定脚本
run_script() {
    local index=$1
    local script_name="${SCRIPTS[$index]}"
    local script_url="${BASE_URL}/${script_name}"
    local tmp_file="/tmp/${script_name}"

    echo "正在下载: ${script_name}"
    if ! wget -q -O "$tmp_file" "$script_url"; then
        echo "❌ 下载失败，请检查网络连接"
        rm -f "$tmp_file"
        return 1
    fi

    chmod +x "$tmp_file"
    echo "===== 开始执行: ${NAMES[$index]} ====="
    bash "$tmp_file"
    rm -f "$tmp_file"
    echo -e "\n===== 执行完成 ====="
    read -p "按回车键返回菜单..." _
}

# 主循环
while true; do
    clear
    echo "=================================="
    echo "  Linux 运维工具合集 v1.0"
    echo "  仓库: BiyaoDev/tools"
    echo "=================================="
    for i in "${!SCRIPTS[@]}"; do
        echo "  $((i+1)). ${NAMES[$i]}"
    done
    echo "  0. 退出"
    echo "=================================="
    read -p "请输入选项 [0-4]: " choice

    case "$choice" in
        0)
            echo "已退出"
            exit 0
            ;;
        1|2|3|4)
            run_script $((choice-1))
            ;;
        *)
            echo "❌ 无效选项，请输入 0-4 的数字"
            sleep 1
            ;;
    esac
done
