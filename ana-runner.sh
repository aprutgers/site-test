#!/bin/sh
sudo chmod 666 /var/run/docker.sock
instance=30
if [ -z "$instance" ]
then
   echo "usage $0 <instance>"
   exit 1
fi
stop_proxy () {
   pid=`ps -edalf|grep psiphon-tunnel-core-x86_64|grep "client${instance}"|grep -v grep|awk '{ print $4 }'`
   if [ ! -z "$pid" ]
   then
      echo "stop_proxy: kill $pid"
      kill $pid
   fi
}
proxywait=5
proxylog="/nvme/tmp/test${instance}-psiphon.log"
drd="-dataRootDirectory /home/ec2-user/site-test/psi/${instance}"
lif="-listenInterface docker0"
psicmd="/home/ec2-user/psiphon.client.free/psiphon-tunnel-core-x86_64 $drd $lif"
echo "ana-runner: starting instance ${instance}"
echo "psiphon proxy logfile=$proxylog"
echo "shuffle proxy order list"
proxy=`ls /home/ec2-user/psiphon.client.free/servers/client${instance}/client*.conf|shuf -n 1`
stop_proxy
echo "start $psicmd -config $proxy to $proxylog"
$psicmd -config $proxy > $proxylog 2>&1 &
echo "sleep $proxywait"
sleep $proxywait
cat $proxylog
if grep 'downstreamBytesPerSecond' $proxylog > /dev/null
then
   echo "proxy working OK"
   ./test.sh $instance $proxy
else
   echo "proxy not working ok, skip to next"
   cat $proxylog
fi
stop_proxy
