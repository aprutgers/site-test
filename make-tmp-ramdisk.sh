#!/bin/sh
cap=2560M
echo creating $cap ramdisk for /mnt/tmp
if [ ! -d /mnt/tmp ]
then
   mkdir /mnt/tmp
fi
mount -t tmpfs -o size=$cap tmpfs /mnt/tmp
# targets from symlinks from /var/lib and /run
mkdir /mnt/tmp/docker
mkdir /mnt/tmp/run
mkdir /mnt/tmp/run/docker
mkdir /mnt/tmp/run/containerd
echo done.
