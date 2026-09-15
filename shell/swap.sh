#!/bin/bash
# swap.sh - Linux VPS 交换分区（Swap）管理脚本
# 功能：创建 / 删除 swap 文件，支持开机自启配置
# 检测：root 权限、OpenVZ 虚拟化环境

# 校验 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# OpenVZ 环境检测（OpenVZ 通常不支持自定义 swap）
if [ -f /proc/vz/veinfo ] || command -v vzctl &> /dev/null; then
    echo "⚠️  检测到 OpenVZ 虚拟化环境，可能不支持自定义交换分区"
    read -p "是否继续？(y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消操作"
        exit 0
    fi
fi

SWAP_FILE="/swapfile"
FSTAB="/etc/fstab"

# 创建交换分区
create_swap() {
    # 检查是否已存在 swap 文件
    if [ -f "$SWAP_FILE" ]; then
        echo "⚠️  检测到已存在交换文件 $SWAP_FILE"
        read -p "是否覆盖重建？(y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "已取消创建"
            return 1
        fi
        # 先关闭再删除旧的
        swapoff "$SWAP_FILE" 2>/dev/null
        rm -f "$SWAP_FILE"
    fi
    read -p "请输入交换分区大小（单位 GB，例如 1）: " size_gb
    # 数值校验
    if ! [[ "$size_gb" =~ ^[0-9]+$ ]] || [ "$size_gb" -le 0 ]; then
        echo "❌ 请输入有效的正整数"
        return 1
    fi
    echo "正在创建 ${size_gb}GB 交换文件，请稍候..."
    # 创建交换文件（使用 1M 块大小，避免小内存机器内存耗尽）
    if ! dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$(( size_gb * 1024 )) status=progress; then
        echo "❌ 交换文件创建失败"
        rm -f "$SWAP_FILE"
        return 1
    fi
    # 设置权限
    chmod 600 "$SWAP_FILE"
    # 格式化为 swap
    if ! mkswap "$SWAP_FILE"; then
        echo "❌ 交换分区格式化失败"
        rm -f "$SWAP_FILE"
        return 1
    fi
    # 启用 swap
    if ! swapon "$SWAP_FILE"; then
        echo "❌ 交换分区启用失败"
        rm -f "$SWAP_FILE"
        return 1
    fi
    echo "✅ ${size_gb}GB 交换分区创建并启用成功"
    # 开机自启配置
    read -p "是否添加到 /etc/fstab 开机自动挂载？(Y/n): " fstab_confirm
    if [ "$fstab_confirm" != "n" ] && [ "$fstab_confirm" != "N" ]; then
        # 避免重复添加
        if grep -q "$SWAP_FILE" "$FSTAB"; then
            echo "ℹ️  /etc/fstab 中已存在该条目，无需重复添加"
        else
            echo "$SWAP_FILE none swap defaults 0 0" >> "$FSTAB"
            echo "✅ 已添加到 /etc/fstab，开机自动挂载"
        fi
    fi
    echo -e "\n当前交换分区状态："
    swapon --show
}


# 主菜单
while true; do
    [ -t 0 ] && clear
    echo "=============================="
    echo "  交换分区管理工具"
    echo "=============================="
    echo "  1. 创建交换分区"
    echo "  2. 删除交换分区"
    echo "  0. 退出"
    echo "=============================="
    read -p "请输入选项 [0-2]: " choice

    case "$choice" in
        1)
            create_swap
            read -p "按回车键返回菜单..." _
            ;;
        2)
            delete_swap
            read -p "按回车键返回菜单..." _
            ;;
        0)
            echo "已退出"
            exit 0
            ;;
        *)
            echo "❌ 无效选项，请输入 0-2 的数字"
            sleep 1
            ;;
    esac
done
