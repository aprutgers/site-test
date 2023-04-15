#!/bin/sh
cap=1024M
echo creating $cap ramdisk for /mnt/tmp
if [ ! -d /mnt/tmp ]
then
   mkdir /mnt/tmp
fi
mount -t tmpfs -o size=$cap tmpfs /mnt/tmp
echo done.
