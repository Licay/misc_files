#!/bin/bash
# Author: casey
# date: 2024-12-11
# 快速挂载多个目录，需要sudo权限。
#  eg. sudo ./mount_all.sh                  # mount
#  eg. sudo ./mount_all.sh remove           # umount

#########################################################################
######################## config that
# 两种验证二选一
# username=""
# password=""
# credentials="username=$username,password=$password"
credentials="credentials=/root/.smbcredentials"

m_list="\n
cifs //myfs/factory_disk                                  /mnt/factory_disk fsc,uid=1000,gid=1000,ro,$credentials \n
cifs //myfs/test                                          /mnt/test fsc,uid=1000,gid=1000,ro,$credentials \n
nfs 172.16.11.12:/home/casey                              /mnt/service \n
"
if [ -f "$(dirname "$0")/mount.config" ]; then
    source "$(dirname "$0")/mount.config"
fi
######################## config end
#########################################################################

cow=`echo -e $m_list | awk '{print $2}'`

check_dir() {
    if [ ! -d "$1" ]; then
        echo "create dir $1"
        mkdir $1
    fi
}

check_result() {
    if [ $1 -eq 0 ]; then
        echo "-- ok!   [mount $2 to $3]"
    else
        echo "-- fail! [mount $2 to $3]"
    fi
}

cnt=1
for dir_src in `echo $cow` ;
do
    let "cnt=cnt+1"
    if [ "$dir_src" ]; then
        tmp=`echo -e $m_list | awk NR==$cnt'{ print $0}'`
        type=`echo $tmp | awk '{print $1}'`
        dir_dst=`echo $tmp | awk '{print $3}'`
        m_cfg=`echo $tmp | awk '{print $4}'`
		if [ "$1" == "remove" ]; then
			echo $cnt umount $dir_dst
			umount $dir_dst
			continue
		fi
        check_dir $dir_dst
        # echo mount -t $type -o $m_cfg $dir_src $dir_dst
        if [ $m_cfg ]; then
            mount -t $type -o $m_cfg $dir_src $dir_dst
        else
            mount -t $type $dir_src $dir_dst
        fi
        check_result $? $dir_src $dir_dst
    fi
done

exit
