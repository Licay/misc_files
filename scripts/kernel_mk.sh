#!/bin/bash

# 简单快速创建一个内核编译环境，不污染内核源码，退出时自动移除编译输出目录。
# 最初的目的是为了给安卓设备快速编译和验证模块代码。
# eg. source kernel_mk.sh kernel_dir config_file

####### 自动进入工作目录，使用示例（使用m替代make动作）
# 内核配置
# m menuconfig
# 编译内核
# m -j16
# 编译模块
# m M=drivers/sample/  modules CONFIG_XXX=m

########################################################
###### config that
ARCH=arm64
CC=aarch64-linux-android26-clang
CROSS_COMPILE=aarch64-linux-android-
# CC=clang
# CROSS_COMPILE=llvm-
########################################################

err_input()
{
    echo "error input!"
    while true; do
        sleep 1
    done
    exit
}

if [ ! -d $1 ]; then
    err_input
fi
if [ ! -f $2 ]; then
    err_input
fi
echo "start $1 check!"

KER_DIR=$(realpath $1)
CONFIG_FILE=$(realpath $2)

WORK_DIR=/tmp/kernel.`date +"%Y-%m-%d.%H_%m_%S"`
OUT_DIR=$WORK_DIR/out

clean_out()
{
	rm -rf $WORK_DIR
}

# trap "echo ctrl+c!!!; clean_out" SIGINT
trap "echo goodbye!!!; clean_out" EXIT

mkdir $WORK_DIR
mkdir $OUT_DIR

# # auto find .config (not support)
# config_list=$WORK_DIR/config.find
# find . -type f -name ".config" > $config_list
# # cat $config_list
# cnt=1
# echo "choose your config (default 0)"
# list=
# while true ; do
#     c=`sed -n ${cnt}p $config_list`
#     if [ "$c" == "" ]; then
#         break
#     fi
#     echo "$cnt: $c"
#     let "cnt=cnt+1"

# done
# read var
# CONFIG_FILE=`pwd`/`sed -n ${var}p $config_list`
# echo "get $CONFIG_FILE"

# cd $WORK_DIR

# 交叉编译
P0="-C $KER_DIR ARCH=$ARCH O=$OUT_DIR"
P1="CROSS_COMPILE=$CROSS_COMPILE"

P_CC="CC=$CC"

# if needed
# P_LD="LD=aarch64-linux-android-ld"
# P_ST="STRIP=aarch64-linux-android-strip"
# P_OBJ="STRIP=aarch64-linux-android-objdump"

alias sync_config="cp $CONFIG_FILE $OUT_DIR"
alias m="make $P0 $P1 $P_CC $P_LD $P_ST $P_OBJ"
alias mmc="m menuconfig"
alias ko="cd $WORK_DIR"
alias mk="m -j`nproc`"

sync_config

echo "enjoy it!"
