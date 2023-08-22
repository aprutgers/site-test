#!/bin/sh

sudo chmod 666 /var/run/docker.sock

instance="$1"
if [ -z "$instance" ]
then
   echo "usage $0 <instance>"
   exit 1
fi
domain=`grep ,$instance, /home/ec2-user/site-test/domains|awk -F: '{ print $1 }'`
if [ -z "$domain" ]
then
   echo "`date`: ERROR: no domain configured for instance $instance"
   exit 1
fi

proxywait=15
proxylog="/nvme/tmp/test${instance}-psiphon.log"
drd="-dataRootDirectory /home/ec2-user/site-test/psi/${instance}"
lif="-listenInterface docker0"
psicmd="/home/ec2-user/psiphon.client.free/psiphon-tunnel-core-x86_64 $drd $lif"

stop_proxy () {
   pid=`ps -edalf|grep psiphon-tunnel-core-x86_64|grep "client${instance}/"|grep -v grep|awk '{ print $4 }'`
   if [ ! -z "$pid" ]
   then
      echo "stop_proxy: kill $pid"
      kill $pid
   fi
}

echo "`date`: test-runner-proxy: starting instance ${instance} ${domain}"
echo "`date`: psiphon proxy logfile=$proxylog"

while [ true ]
do
   proxy=`ls /home/ec2-user/psiphon.client.free/servers/client${instance}/client*.conf|shuf -n 1`
   stop_proxy
   ruby /home/ec2-user/site-test/waiter.rb "$instance" "$domain"
   echo "`date`: start $psicmd -config $proxy to $proxylog"
   $psicmd -config "$proxy" > $proxylog 2>&1 &
   echo "`date`: sleep $proxywait"
   sleep $proxywait
   if grep 'downstreamBytesPerSecond' $proxylog > /dev/null
   then
      echo "`date`: proxy working OK"
      ./test.sh "$instance" "$proxy"
   else
      echo "`date`: proxy not working ok, skip to next"
   fi
   stop_proxy
done
