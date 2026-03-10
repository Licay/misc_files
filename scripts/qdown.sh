#!/bin/zsh

MFLASH=`where mflash`
if [ "$MFLASH" = "" ]; then
    echo "mflash not found"
    exit 1
fi

FIRMWARE=$1
if [ "$FIRMWARE" = "" ]; then
    echo "please input firmware path"
    exit 1
fi

sudo bash -c "export PATH=$PATH; cd $FIRMWARE; mflash ./; exit"

# notify user download complete, and time
DATE=`date +'%Y-%m-%d %H:%M:%S'`
notify-send "Download complete" "The firmware has been downloaded successfully.\nnow: $DATE"
