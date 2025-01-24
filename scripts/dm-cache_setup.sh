#!/bin/bash
# author: casey
# date: 2025-01-13
# 描述: 使用 dm-cache 将 /ssd_cache_data 和 /ssd_cache 文件作为 /dev/sdb1 磁盘的缓存加速。
# 参数:
#   $1 - 操作类型 (setup, run, exit)
#   $2 - 挂载地址 (仅在 run 操作时需要)

# 检查参数数量
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {setup|run|exit} [mount_point]"
    exit 1
fi

# 操作类型
ACTION=$1
MOUNT_POINT=$2

# 使用文件作为缓存设备
# SSD_DATA_FILE=/ssd_cache_data
# SSD_META_FILE=/ssd_cache
# 直接使用分区设备作为缓存设备
SSD1=/dev/sda4  # meta
SSD2=/dev/sda5  # data
HDD=/dev/sdb1   # cached device
CACHE_META=/dev/mapper/cache_meta
CACHE=/dev/mapper/cache
CACHE_DEV=/dev/mapper/cache_dev

# 创建循环设备
setup_loop_device() {
    local file=$1
    local loop_device=$(sudo losetup -f)
    sudo losetup $loop_device $file
    echo $loop_device
}

# 初始化 (setup)
if [ "$ACTION" == "setup" ]; then
    echo "Setting up dm-cache..."

    # 创建缓存数据文件和元数据文件
    # sudo dd if=/dev/zero of=$SSD_DATA_FILE bs=1M count=102400
    # sudo dd if=/dev/zero of=$SSD_META_FILE bs=1M count=2048

    # 设置循环设备
    # SSD1=$(setup_loop_device $SSD_META_FILE)
    # SSD2=$(setup_loop_device $SSD_DATA_FILE)

    # 创建缓存元数据设备
    sudo dmsetup create cache_meta --table "0 $(blockdev --getsize $SSD1) linear $SSD1 0"
    if [ $FIRST ]; then
        sudo dd if=/dev/zero of=/dev/mapper/cache_meta # 第一次或修复，需要
        echo "clean mate data!"
    # exit 0
    fi

    # 创建缓存设备
    sudo dmsetup create cache --table "0 $(blockdev --getsize $SSD2) linear $SSD2 0"
    # 创建缓存映射设备
    sudo dmsetup create cache_dev --table "0 $(blockdev --getsize $HDD) cache $CACHE_META $CACHE $HDD 1024 1 writeback default 0"
    echo "dm-cache setup completed."

# 映射 (run)
elif [ "$ACTION" == "run" ]; then
    if [ -z "$MOUNT_POINT" ]; then
        echo "Mount point is required for run action."
        exit 1
    fi
    echo "Mapping and mounting cache device..."
    # 挂载缓存设备
    sudo mount $CACHE_DEV $MOUNT_POINT
    echo "Cache device mounted at $MOUNT_POINT."

# 卸载 (exit)
elif [ "$ACTION" == "exit" ]; then
    echo "Unmounting and removing cache device..."
    # 卸载缓存设备
    sudo umount $CACHE_DEV
    # 移除缓存映射设备
    sudo dmsetup remove cache_dev
    sudo dmsetup remove cache
    sudo dmsetup remove cache_meta
    # 解除循环设备
    sudo losetup -d $(losetup -j $SSD_META_FILE | cut -d: -f1)
    sudo losetup -d $(losetup -j $SSD_DATA_FILE | cut -d: -f1)
    echo "Cache device unmounted and removed."

# 无效操作
else
    echo "Invalid action: $ACTION"
    echo "Usage: $0 {setup|run|exit} [mount_point]"
    exit 1
fi
