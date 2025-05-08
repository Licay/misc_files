## Qemu 快速启动

安装qemu并编译kernel、ramfs

```Bash
sudo apt install qemu-system-arm wget unzip
git clone git://git.buildroot.net/buildroot --depth=1

cd buildroot
# export FORCE_UNSAFE_CONFIGURE=1
make qemu_aarch64_virt_defconfig
# 配置使用initramfs
make menuconfig
make

# 可选替换Linux内核
cp your/kernel/Image output/images/Image
# 运行脚本直接启动qemu
output/images/start-qemu.sh
```

可选修改启动命令进行配置以及共享目录。

```Bash
exec qemu-system-aarch64 -M virt -cpu cortex-a53 -nographic -m 4G -smp 8 -kernel Image -append "rootwait root=/dev/vda console=ttyAMA0" -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 -drive file=rootfs.ext4,if=none,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  ${EXTRA_ARGS} "$@" \
-virtfs local,path=/mnt/hdd-cached/ko,mount_tag=host_share,security_model=mapped
```

## 免编译

此处提供已编译好的示例文件，可以直接运行`start-qemu.sh`启动。

ENV && EXAMPLE

```bash
-> % cd buildroot
-> % git log
commit dd2d62a36e091ad745fbacbef810709b2f597396 (grafted, HEAD -> master, origin/master, origin/HEAD)
Author: Romain Naour <romain.naour@smile.fr>
Date:   Wed May 7 21:39:43 2025 +0200

    package/qemu: bump to version 10.0.0

    Changes log:
    https://wiki.qemu.org/ChangeLog/10.0
... ...
-> % qemu-system-aarch64 --version
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.4)
Copyright (c) 2003-2023 Fabrice Bellard and the QEMU Project developers

-> % ./start-qemu.sh
... ...
deleting routers
adding dns 10.0.2.3
OK
Starting crond: OK

Welcome to Buildroot
buildroot login: root
#
# uname -a
Linux buildroot 6.12.9 #2 SMP Thu May  8 04:11:32 UTC 2025 aarch64 GNU/Linux
#
```
