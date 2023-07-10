#!/bin/bash

cd /home/ec2-user/site-test
pids=`ps -edalf|grep test-runner|grep -v grep|awk '{ print $4 }'`
if  [ -z "$pids" ]
then
   echo "no test-runners found"
fi
echo stopping test-runnner $pids
for pid  in $pids
do
   echo kill $pid
   kill $pid
done
pids=`ps -edalf|grep runner|grep -v grep|awk '{ print $4 }'`
echo runner pids=$pids
if  [ -z "$pids" ]
then
   echo "no runners found"
fi
echo stopping runner $pids
for pid  in $pids
do
   echo kill $pid
   kill $pid
done
pids=`ps -edalf|grep waiter|grep -v grep|awk '{ print $4 }'`
if  [ -z "$pids" ]
then
   echo "no waiters found"
fi

echo stopping waiter $pids
for pid  in $pids
do
   echo kill $pid
   kill $pid
done

echo cooldown sleep 3
sleep 3

echo stop and remove all containers

dids=`docker ps -a|grep -v smokeping|awk '{ print $1 }'|grep -v CONT`
echo stopping docker ids $dids
for did  in $dids
do
   echo docker kill and rm $did
   docker kill $did
   docker rm $did
done

killall psiphon-tunnel-core-x86_64
