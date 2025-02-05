#!/bin/zsh

THIS=`realpath $0`
NAME=`basename $THIS`
alias have_$NAME="echo 'you are using' $THIS"

export LTO=thin

alias frf="fastboot reboot fastboot"
alias ff="fastboot --disable-verity flash"

alias aremount="adb root; adb remount"
alias ashell="adb shell"
alias apush="adb push"

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

export ENV_HELP="support functions:"
export ENV_HELP=$ENV_HELP"
    - adb
        - pko: adb push to /vendor_dlkm/lib/modules
        - aremount: adb root and remount
        - ashell: adb shell
        - apush: adb push
    - fastboot
        - frf: fastboot reboot fastboot
        - ff: fastboot --disable-verity flash
    - repo
        - go_repo: navigate to the root of the repo
        - repo_fix_project: fix the project's .git directory
        - repo_go_project: go to the project's real directory
"

help() {
    echo "$ENV_HELP"
}
alias h="help"
