#!/bin/sh
while true 
do
   dockers=`docker ps|wc -l`
   load=`cat /proc/loadavg | cut -d' ' -f1|cut -d. -f1`
   free=`free -m|grep Mem|awk '{ print $4 }'`
   echo "`date`: #dockers: $dockers load: $load free: ${free} MB"
   sleep 1
done
