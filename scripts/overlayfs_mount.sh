#!/bin/bash

# 脚本名称: overlayfs_mount.sh
# 功能: 快速挂载或卸载 overlayfs
# 使用方法: ./overlayfs_mount.sh [mount|umount] <挂载点> <上层目录> <下层目录>
# 注意事项：
# - 确保上层目录和下层目录存在。
# - 挂载时需要提供上层目录和下层目录，卸载时只需提供挂载点。
# - 如果挂载或卸载失败，脚本会输出错误信息。

# 检查参数数量
if [ $# -lt 2 ]; then
    echo "使用方法: $0 [mount|umount] <挂载点> [上层目录] [下层目录]"
    exit 1
fi

ACTION=$1
MOUNT_POINT=$2
UPPER_DIR=$3
LOWER_DIR=$4

case $ACTION in
    mount)
        if [ -z "$UPPER_DIR" ] || [ -z "$LOWER_DIR" ]; then
            echo "挂载操作需要提供上层目录和下层目录"
            exit 1
        fi
        echo "挂载 overlayfs 到 $MOUNT_POINT ..."
        mkdir -p "$MOUNT_POINT"
        mount -t overlay overlay -o lowerdir="$LOWER_DIR",upperdir="$UPPER_DIR",workdir="$UPPER_DIR.work" "$MOUNT_POINT"
        if [ $? -eq 0 ]; then
            echo "挂载成功!"
        else
            echo "挂载失败!"
        fi
        ;;
    umount)
        echo "卸载 $MOUNT_POINT ..."
        umount "$MOUNT_POINT"
        if [ $? -eq 0 ]; then
            echo "卸载成功!"
        else
            echo "卸载失败!"
        fi
        ;;
    *)
        echo "未知操作: $ACTION"
        echo "使用方法: $0 [mount|umount] <挂载点> [上层目录] [下层目录]"
        exit 1
        ;;
esac