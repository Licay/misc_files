#!/bin/bash

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
