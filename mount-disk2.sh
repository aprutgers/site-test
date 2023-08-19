#!/bin/sh

# update the grepped part ids when new partitions are created
swapdev=`blkid|grep 1b3c751f-e3a3-dc42-84d6-60ff1e7b2be8|awk -F: '{ print $1 }'`
disk2dev=`blkid|grep ee35036f-6d12-a84d-a6fb-706b01eb6d8a|awk -F: '{ print $1 }'`

echo "found swapdev=$swapdev"
echo "found disk2dev=$disk2dev"

if [ -z "$swapdev" ]
then
   echo "ERROR: could not find swap parition on disk2 device"
   exit 1
fi
if [ -z "$disk2dev" ]
then
   echo "ERROR: could not find disk2 parition on disk2 device"
   exit 1
fi
if [ -e $swapdev ]
then
   letter=${swapdev:7:1}
   priority=`printf %d\\\n \'$letter`
   priority=`echo "$priority + 100"|bc -l`
   echo "swapon $swapdev  -p $priority"
   swapon "$swapdev" -p $priority
   swapon
   # assume we have found disk2dev too
   mkdir -p /disks2
   mount "$disk2dev" /disk2
   exit 0
else
   echo "ERROR: could not find $swapdev"
   lsblk
   exit 1
fi
