#!/bin/zsh

THIS=`realpath $0`
NAME=`basename $THIS`
alias have_$NAME="echo 'you are using' $THIS"

export LTO=thin

alias frf="fastboot reboot fastboot"
alias ff="fastboot --disable-verity flash"

aroot() {
    while true; do
        adb root
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
}

ashell() {
    echo
    while true; do
        # 回到上一行开头并清除当前行
        echo -en "\033[1A\033[K"
        adb shell
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
}

alias aremount="aroot; adb remount"
# alias ashell="adb shell"
alias apush="adb push"
alias adevices="adb devices"
alias areboot="adb reboot"

pko() {
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

export ENV_HELP="support functions:"
export ENV_HELP=$ENV_HELP"
    - adb
        - pko: adb push to /vendor_dlkm/lib/modules
        - aremount: adb root and remount
        - ashell: adb shell
        - apush: adb push
        - aroot: adb root
        - adevices: adb devices
        - areboot: adb reboot
    - fastboot
        - frf: fastboot reboot fastboot
        - ff: fastboot --disable-verity flash
    - repo
        - go_repo: navigate to the root of the repo
        - repo_fix_project: fix the project's .git directory
        - repo_go_project: go to the project's real directory
    - others
        - reboot: for safe
        - cp_code: copy code to a file
        - have_env_normal: show the current script
        - help: show this help
        - sync_env: pull this git
"

help() {
    echo "$ENV_HELP"
}
alias h="help"
