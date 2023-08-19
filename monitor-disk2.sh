#!/bin/sh
swapdev=`swapon|grep sd|awk '{ print $1 }'|cut -d / -f3|tail -1`
echo "swapdev=/dev/$swapdev"
lsblk|grep $swapdev>/dev/null
if [ "$?" != 0 ]
then
   if [ ! -f /tmp/disk2-alerted ]
   then
      echo "`date`:FAIL - /dev/$swapdev seems to be gone?? - sending ALERT"
      echo "`date`:FAIL - /dev/$swapdev seems to be gone??" > /tmp/disk2-alert.txt
      lsblk >> /tmp/disk2-alert.txt
      dmesg|grep usb >> /tmp/disk2-alert.txt
      sudo tail -10 /var/log/messages >> /tmp/disk2-alert.txt
      /home/ec2-user/sendgrid/send_email.sh "DISK2 ALERT !!!" /tmp/disk2-alert.txt /tmp/disk2-alert.txt
      touch /tmp/disk2-alerted
      echo "attempt to self-recover as disk device flipped to another /dev/sdx"
      sudo systemctl restart mount-disk2
   else
      echo "`date`:FAIL - /dev/$swapdev seems to be gone?? - ALERT was sent."
      lsblk
   fi
else
   /bin/rm -f /tmp/disk2-alerted
   echo "`date`: all good -  swap /dev/$swapdev is still there"
fi
