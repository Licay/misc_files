#!/bin/zsh

alias have_env_normal="echo 'you are using env_normal.sh'"

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
        exit 0
    fi

    echo "do not support!"
    exit -1
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
fix_project() {
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
