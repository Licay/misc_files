#!/bin/zsh

THIS=`realpath $0`
NAME=`basename $THIS`
alias have_$NAME="echo 'you are using' $THIS"

shell=`cat /proc/$$/cmdline`
shell=`basename $shell`

LOCAL_DIR=~/.local/bin

export ENV_HELP="support functions:"
export ENV_HELP=$ENV_HELP"
    - adb
        - adb_sn_set: set adb serial number
        - adb_sn: adb with serial number
        - adb_waiting_dev: wait for device
        - pko: adb_sn push to /vendor_dlkm/lib/modules
        - aremount: adb_sn root and remount
        - ashell: adb_sn shell
        - apush: adb_sn push
        - aroot: adb_sn root
        - adevices: adb devices
        - areboot: adb_sn reboot
        - adb_wait_for_boot_ok: wait for boot ok
    - fastboot
        - frf: fastboot reboot fastboot
        - ff: fastboot --disable-verity flash
    - repo
        - go_repo: navigate to the root of the repo
        - repo_fix_project: fix the project's .git directory
        - repo_go_project: go to the project's real directory
    - rime
        - rime_update: update rime register
    - others
        - reboot: for safe
        - cp_code: copy code to a file
        - have_env_normal: show the current script
        - help: show this help
        - sync_env: pull this git
        - cp_find_name: copy file with name
            eg: cp_find_name src_dir name dst_dir
        - notify_done: notify user command done
        - env_resource: resource environment for current shell
"

# { @protected_func }
help() {
    echo "$ENV_HELP"
}
alias h="help"

export LTO=thin

alias frf="fastboot reboot fastboot"
alias ff="fastboot --disable-verity flash"

export ADB_SN
alias aroot="adb_waiting_dev; adb_sn root"
alias aremount="aroot; adb_sn remount"
alias ashell="adb_waiting_dev; adb_sn shell"
alias apush="adb_waiting_dev; adb_sn push"
alias apull="adb_waiting_dev; adb_sn pull"
alias adevices="adb devices"
alias areboot="adb_waiting_dev; adb_sn reboot"

alias notify_done="notify-send 'Command done!' 'The operation has been completed!\n$(date +'%Y-%m-%d %H:%M:%S')'"

if [ "$FUNC_FAST" = "" ]; then
    export FUNC_FAST=1
fi

if [ "$FUNC_FAST" = "0" ]; then
    cv2bin_path=`dirname $THIS`/../bin
    cv2bin_path=`realpath $cv2bin_path`
    if [ ! -d $cv2bin_path ]; then
        # fast convert function to bin file
        src_file=$THIS
        dist_dir=$cv2bin_path
        mkdir -p $dist_dir
        func_list=$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' $src_file | sed 's/() *{//' | tr -d ' ')

        for func in `echo $func_list`; do
            # "# { ... }" under the func, if "@protected_func" exist, ignore it
            grep -A1 "^# {.*@protected_func.*}" $src_file | grep -q "^$func\s*()"
            if [ $? -eq 0 ]; then
                echo "ignore protected func: $func"
                continue
            fi

            echo ">>> $func"
            echo "#!/bin/zsh" > $dist_dir/$func
            echo >> $dist_dir/$func

            echo "export FUNC_FAST=1" >> $dist_dir/$func
            echo "source $THIS" >> $dist_dir/$func
            echo "$func \$@" >> $dist_dir/$func
        done
        chmod +x $dist_dir/*
    fi
    export PATH=$PATH:$cv2bin_path
    return 0
fi

# { @protected_func }
adb_sn_set() {
    local link_dev=($(adb devices | grep -v "List" | grep "device$" | awk '{print $1}'))
    local dev_count=${#link_dev[@]}

    if [ $dev_count -eq 1 ]; then
        export ADB_SN="${link_dev[1]}"
        echo "set ADB_SN to $ADB_SN"
        return 0
    fi

    echo "choose adb serial number:"
    cnt=0
    for i in $link_dev; do
        cnt=$((cnt + 1))
        echo "$cnt: $i"
    done
    echo "other: clear"
    echo -n "input: "
    read -r num

    if [ "$num" = "" ]; then
        export ADB_SN=""
    else
        export ADB_SN=`echo $link_dev | awk -v num=$num '{print $num}'`
    fi
    echo "set ADB_SN to $ADB_SN"
}

adb_sn() {
    if [ "$ADB_SN" = "" ]; then
        adb_sn_set
        if [ "$ADB_SN" = "" ]; then
            adb $@
            return 0
        fi
    fi

    adb -s $ADB_SN $@
}

adb_waiting_dev() {
    # 检查是否有设备连接
    ADB_DEV="device$"
    if [ "$ADB_SN" != "" ]; then
        ADB_DEV=$ADB_SN
    fi

    adb devices | grep -q "$ADB_DEV"
    if [ $? -ne 0 ]; then
        # 如果没有设备连接，则等待设备连接
        echo -n "waiting ."
        while true; do
            echo -n "."
            adb devices | grep -q "$ADB_DEV"
            if [ $? -eq 0 ]; then
                echo
                break
            fi
            sleep 0.5
        done
    fi
}

adb_swipe_while() {
    local duration=${1:-300}  # 默认持续时间为300毫秒
    local interval=${2:-3}  # 默认间隔时间为3000毫秒

    while true; do
        ashell input swipe 500 1500 500 500 $duration
        sleep $interval
    done
}

# ashell() {
#     echo
#     while true; do
#         # 回到上一行开头并清除当前行
#         echo -en "\033[1A\033[K"
#         adb shell "$@"
#         if [ $? -eq 0 ]; then
#             break
#         fi
#         sleep 1
#     done
# }

adb_get_apk_path() {
    local package_name="$1"
    local apk_path=$(ashell pm path "$package_name" 2>/dev/null)

    if [ -z "$apk_path" ] || ! echo "$apk_path" | grep -q "package:"; then
        echo -e "未找到包名为 '$package_name' 的应用"
        exit 1
    fi

    echo "${apk_path#package:}" # 去掉 "package:" 前缀
}

adb_pull_apk() {
    local packages=("$@")
    local output_dir="${packages[-1]}"

    # echo "packages: ${packages[@]}"
    # echo "output_dir: $output_dir"
    if [ -z "$packages" ] || [ ! -d "$output_dir" ]; then
        echo "用法: adb_pull_apk <包名1> [包名2]... <输出目录>"
        return 1
    fi

    if [ "$ADB_SN" = "" ]; then
        adb_sn_set
    fi
    adb_waiting_dev

    for package_name in "${packages[@]:0:${#packages[@]}-1}"; do
        if [ -z "$package_name" ]; then
            continue
        fi

        apk_path=`adb_get_apk_path "$package_name"`
        if [ $? -ne 0 ]; then
            echo -e "获取包名 '$package_name' 的 APK 路径失败"
            continue
        fi
        echo "正在从设备中拉取 APK: $apk_path"
        apull "$apk_path" "$output_dir/$package_name.apk"
    done
}

adb_wait_for_boot_ok() {
    # 定义常量
    readonly POWER_KEY=26
    readonly ENTER_KEY=98

    if [ "$1" = "-s" ] && [ -n "$2" ]; then
        export ADB_SN="$2"
        echo "set ADB_SN to $ADB_SN"
    fi

    ashell uname -a

    soc_vendor=$(ashell getprop ro.soc.vendor)
    echo "检测到设备: SOC厂商 = $soc_vendor"
    sleep 1

    # 根据SOC厂商读取亮度值
    case $soc_vendor in
        "qcom")
            brightness=$(ashell cat /sys/class/backlight/panel0-backlight/brightness 2>/dev/null)
            ashell "echo 160 > /sys/class/backlight/panel0-backlight/brightness"
            ;;
        "sprd")
            brightness=$(ashell cat /sys/class/backlight/sprd_backlight/brightness 2>/dev/null)
            ashell "echo 160 > /sys/class/backlight/sprd_backlight/brightness"
            ;;
        *)
            echo "警告: 未知的SOC厂商: $soc_vendor"
            brightness=0
            ;;
    esac

    echo "亮度值: $brightness"
    # echo "点亮屏幕..."
    # ashell input keyevent KEYCODE_WAKEUP  # 或数字代码224[6,7](@ref)
    # echo "模拟按键解锁..."
    # ashell input keyevent $ENTER_KEY   # 可能误触发app

    # 部分设备在锁屏时触发菜单键会自动点亮屏幕并显示解锁界面
    ashell input keyevent 82  # 触发菜单键（KEYCODE_MENU）[1,2,7](@ref)
    ashell input keyevent 82  # 触发菜单键（KEYCODE_MENU）[1,2,7](@ref)
    ashell cmd media_session volume --stream 1 --set 0
    ashell cmd media_session volume --stream 2 --set 0
    ashell cmd media_session volume --stream 3 --set 0

    ashell settings put system screen_off_timeout 2147483647  # 约24.8天超时[1](@ref)
    # 关闭自动旋转
    ashell settings put system accelerometer_rotation 0
    # ashell settings put system screen_brightness 8192
    ashell settings put system screen_brightness 4096

    echo "设备启动完成"
    return 0
}

pko() {
    adb_waiting_dev
    adb push $1 /vendor_dlkm/lib/modules
}

# for error ctrl
reboot() {
    if [ ! -z $1 ]; then
        echo "reboot now!"
        systemctl reboot
        return 0
    fi

    echo "do not support!"
    return -1
}

########################################################################
# for repo
########################################################################

go_repo() {
    NOW=`pwd`
    while [ "$PWD" != "/" ]; do
        if [ -d ".repo" ]; then
            return 0
        fi
        cd ..
    done

    echo "Not in a repo project."
    cd "$NOW"
    return 1
}

# if remove or dirty the project's .git directory, this command will fix it
# the repo directory is needed
repo_fix_project() {
    if [ ! -d "$1" ]; then
        echo "Directory $1 does not exist."
        mkdir -p "$1"
    fi

    cd "$1"
    TMP1=`pwd`
    rm .git* -rf

    go_repo
    TMP2=`pwd`
    BRANCH=$(basename "$PWD")
    PRJ_DIR=${TMP1#$TMP2/}
    CONFIG=.repo/projects/$PRJ_DIR.git/config
    if [ ! -f "$CONFIG" ]; then
        echo "File $CONFIG does not exist."
        return 1
    fi

    PRJ=$(grep "projectname = " $CONFIG | sed 's/projectname = //')
    PRJ=$(echo $PRJ | tr -d ' \t')

    echo --- repo sync $PRJ
    repo sync $PRJ

    echo --- repo start $BRANCH $PRJ
    repo start $BRANCH $PRJ

    cd "$TMP1"
}

# go to the project real directory
repo_go_project() {
    PRJ=$1
    go_repo
    BASE=`pwd`

    cd .repo/projects
    for config in $(find . -name "config"); do
        if grep -q "$PRJ" "$config"; then
            PRJ_DIR=$config
            # echo "Found '$PRJ' in $config"
            break;
        fi
    done

    PRJ_DIR=${PRJ_DIR%.git/config}
    PRJ_DIR=$BASE/$PRJ_DIR
    echo $PRJ_DIR
    cd $PRJ_DIR
}

# copy code to a file
# $1...: output file
# $... : file type
cp_code() {
    if [ $# -lt 2 ]; then
        echo "error input!"
        echo "usage: cp_code output_file file_type1 file_type2 ..."
        return -1
    fi

    out=$1
    echo > $out

    for type in ${@:2}; do
        find . -type f -name "$type" | while read -r file; do
            echo "[文件名：$file]"
            echo "[文件名：$file]" >> $out
            cat "$file" >> $out
        done
    done
}

sync_env() {
    if [ ! -e $THIS ]; then
        return -1
    fi

    dir=`dirname $THIS`

    cd $dir
    git pull
    cd -

    . $THIS
}

# rime
rime_update() {
    cd ~/.config/ibus/rime
    cp default.yaml default.yaml.old
    git checkout .
    git pull --depth 1
    cp default.yaml.old default.yaml
    ibus restart
}

cp_find_name() {
    src=$1
    name=$2
    dst=$3

    cp `find $src -name "$name"` $dst
}

env_resource() {
    # shell=`basename $SHELL`
    if [ -z "$shell" ]; then
        echo "Error: Unable to determine the shell."
        return 1
    fi

    echo "Resource environment for $shell..."
    source ~/.${shell}rc
}

history_gp() {
    if [ -z "$1" ]; then
        echo "usage: history_gp <pattern>"
        return 1
    fi

    history | grep --color=auto "$1"
}

convert_func2bin() {
    if [ $# -lt 2 ]; then
        echo "usage: convert_func2bin <source_file> <dist_dir>"
        return 1
    fi

    src_file=$1
    dist_dir=$2
    mkdir -p $dist_dir
    func_list=$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' $src_file | sed 's/() *{//' | tr -d ' ')

    for func in `echo $func_list`; do
        # "# { ... }" under the func, if "@protected_func" exist, ignore it
        grep -A1 "^# {.*@protected_func.*}" $src_file | grep -q "^$func\s*()"
        if [ $? -eq 0 ]; then
            echo "ignore protected func: $func"
            continue
        fi

        echo ">>> $func"
        echo "#!/bin/zsh" > $dist_dir/$func
        # copy "{ * }" to bin file
        echo >> $dist_dir/$func
        echo "this_func() {" >> $dist_dir/$func
        sed -n "/^$func\s*()/,/^}/p" $src_file | sed '1d;$d' >> $dist_dir/$func
        echo "}" >> $dist_dir/$func

        echo >> $dist_dir/$func
        echo "this_func \$@" >> $dist_dir/$func

        chmod +x $dist_dir/$func
    done
}
