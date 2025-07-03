#!/bin/bash

# 简单快速创建一个内核编译环境，不污染内核源码，退出时自动移除编译输出目录。
# 最初的目的是为了给安卓设备快速编译和验证模块代码。
# eg. source kernel_mk.sh kernel_dir config_file
#     WORK_DIR=/your_work_dir source kernel_mk.sh kernel_dir config_file

####### 自动进入工作目录，使用示例（使用m替代make动作）
# 内核配置
# m menuconfig
# 编译内核
# m -j16
# 编译模块
# m M=drivers/sample/  modules CONFIG_XXX=m

########################################################
###### config that for build kernel
ARCH=arm64
# CC=aarch64-linux-android26-clang
# CROSS_COMPILE=aarch64-linux-android-
CC=clang
M_PARAMS="LLVM=1 LD=ld.lld NM=llvm-nm OBJDUMP=llvm-objdump READELF=llvm-readelf AR=llvm-ar STRIP=llvm-strip OBJSIZE=llvm-size"
CROSS_COMPILE=
########################################################

# https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/prebuilts/clang/host/linux-x86
# https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/prebuilts/build-tools
# https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

########################################################
###### config that for build environment
# TOOLCHAIN_BRANCH="main"
# TOOLCHAIN_BRANCH="android-15.0.0_r0.2"
TOOLCHAIN_BRANCH="llvm-r510928"
PREBUILTS_DIR=./prebuilts-$TOOLCHAIN_BRANCH
MIRROR="https://android.googlesource.com"
# MIRROR="https://mirrors.tuna.tsinghua.edu.cn/git/AOSP"
# MIRROR="https://mirrors.ustc.edu.cn/aosp"
########################################################
if [ "$setup" = "1" ]; then
    echo "setup prebuilts"
    mkdir -p $PREBUILTS_DIR
    cd $PREBUILTS_DIR
    if [ ! -d linux-x86 ]; then
        # ${PREBUILTS_DIR}/linux-x86
        git clone "$MIRROR/platform/prebuilts/clang/host/linux-x86" --depth=1 --branch=$TOOLCHAIN_BRANCH
        rm -rf linux-x86/.git
    fi
    if [ ! -d build-tools ]; then
        # ${PREBUILTS_DIR}/build-tools
        git clone "$MIRROR/platform/prebuilts/build-tools" --depth=1 --branch=$TOOLCHAIN_BRANCH
        rm -rf build-tools/.git
    fi
    if [ ! -d aarch64-linux-android-4.9 ]; then
        # ${PREBUILTS_DIR}/aarch64-linux-android-4.9
        git clone "$MIRROR/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9" --depth=1 --branch=main
        rm -rf aarch64-linux-android-4.9/.git
    fi
    cd - >> /dev/null
fi

export PATH=$PATH:${PREBUILTS_DIR}/linux-x86/clang-r510928/bin
# for pahole
export PATH=$PATH:${PREBUILTS_DIR}/build-tools/linux-x86/bin
export PATH=$PATH:${PREBUILTS_DIR}/aarch64-linux-android-4.9/bin

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

if [ "$WORK_DIR" == "" ]; then
    WORK_DIR=/tmp/kernel.`date +"%Y-%m-%d.%H_%m_%S"`
    echo "create work dir $WORK_DIR"
fi

OUT_DIR=$WORK_DIR/out
KER_SRC=$WORK_DIR/kernel_src

clean_out()
{
    echo goodbye!!!
	rm -rf $WORK_DIR
    exit 0
}

# trap "echo ctrl+c!!!; clean_out" SIGINT
# trap "clean_out" EXIT

# mkdir $WORK_DIR
mkdir -p $OUT_DIR
rm -rf $KER_SRC
ln -s $KER_DIR $KER_SRC

# 交叉编译
P0="-C $KER_SRC ARCH=$ARCH O=$OUT_DIR"
P1="CROSS_COMPILE=$CROSS_COMPILE"

P_CC="CC=$CC"

alias sync_config="echo sync config file! ;cp $CONFIG_FILE $OUT_DIR/.config"
alias m="make $P0 $P1 $P_CC $M_PARAMS"
alias mmc="m menuconfig"
alias ko="cd $WORK_DIR"
alias mk="m -j`nproc`"

__help()
{
    echo "------------------- kernel build helper -------------------"
    echo "m: make kernel"
    echo "mmc: make menuconfig"
    echo "ko: cd $WORK_DIR"
    echo "mk: m -j`nproc`"
    echo "sync_config: sync your config file to $OUT_DIR/.config"
    echo "clean_out: clean work dir and exit"
    echo "-----------------------------------------------------------"
}

if [ -f $OUT_DIR/.config ]; then
    echo "kernel config file already exist, do you want to sync it? [y/n]"
    read -r answer
    if [ "$answer" == "y" ]; then
        sync_config
    fi
else
    sync_config
fi

# for user version, make fake abi_symbollist.raw
touch $OUT_DIR/abi_symbollist.raw

__help
echo "enjoy it!"
