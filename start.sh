#!/bin/sh
cd /home/ec2-user/site-test
clients=22
interval=3
echo start with interval $sleep seconds $clients test runner instances ...
c=1
while [ $c -le $clients ]
do
   echo starting instance $c...
   nohup /home/ec2-user/site-test/test-runner.sh $c >> /mnt/tmp/test-runner-instance$c.log 2>&1 &
   echo started instance $c done.
   sleep $interval
   c=$(( $c + 1 ))
   w
done
echo $clients times test instance started see /mnt/tmp/test-runner-instance*.log
# keep running when started from systemd as this shell is parent of all forked runners
if [ "$1" == "systemd" ]
then
   while true
   do
     echo "started as systemd sleep 5000 seconds"
     sleep 5000
   done
fi
