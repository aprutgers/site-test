#!/bin/bash
echo "starting /root/sitetestWebDevReloader.sh/.."
while true
do
   /bin/inotifywait --exclude .swp -e modify /home/ec2-user/site-test/*.py
   echo "Detected python code change in /home/ec2-user/site-test/"
   echo "Executing: systemctl start/stop sitetest web app"
   systemctl stop sitetestweb
   sleep 1
   systemctl status sitetestweb
   sleep 1
   systemctl start sitetestweb
   sleep 1
   systemctl status sitetestweb
   echo "restart sitetestweb done"
done
