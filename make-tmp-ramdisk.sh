#!/bin/sh
cap=2560M
echo creating $cap ramdisk for /mnt/tmp
if [ ! -d /mnt/tmp ]
then
   mkdir /mnt/tmp
fi
mount -t tmpfs -o size=$cap tmpfs /mnt/tmp
mkdir /mnt/tmp/docker
echo done.
