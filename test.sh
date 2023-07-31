#!/bin/sh

instance=$1
psiproxy=$2
dsleep=8
port=$(( 5000 + $instance))
proxyport=$(( 8080 + $instance))
proxy="http://host.docker.internal:${proxyport}"
name="run$port"
country=""
active="true"

if [ -z "$instance" ]
then
  echo "usage: $0 <instance>"
  exit 1
fi

if ! [[ $instance =~ [1-9] ]]
then
   echo "instance should be between 1-20"
   exit 2
fi

safe_stop_docker() {
   name="$1"
   id=`docker ps -a|grep $name|awk '{print $1}'`
   if [ ! -z "$id" ]
   then
      #echo "docker kill $name - $id"
      docker kill $id
      docker rm $id
   #else
      #echo "docker $name not running"
   fi
}

#
# Determine country name for active proxy using ipapi.co service and docker curl 
# which can see the docker internal network; notice grev -v in cmd below removes first line csv header.
# Also cache the country name to reduce requests
# 
#echo get_cached_country for psiproxy=$psiproxy
id=`echo $psiproxy|cut -d. -f5`
#echo id=$id
if [ -f /home/ec2-user/site-test/countrycache/$id ]
then
   #echo "using cache for id=$id"
   country=`cat /home/ec2-user/site-test/countrycache/$id`
   #echo "country=$country"
else
   country=`docker run --add-host=host.docker.internal:host-gateway --rm curlimages/curl -s -x $proxy https://ipapi.co/csv|grep -v country|cut -d, -f10`
   #echo "$country" > /home/ec2-user/site-test/countrycache/$id
   #echo "country=$country"
fi

#echo "create ramdisk storage for chrome session to reduce SSD writes/wear"
chromedir="/mnt/tmp/chrome${instance}"
sudo rm -rf $chromedir
mkdir $chromedir
chmod -R 777 $chromedir
#echo "create ramdisk $chromedir done."

domain=`grep ,$instance, domains|awk -F: '{ print $1 }'`
if [ -z "$domain" ]
then
   echo "FATAL: no domain configured for instance $instance - bailing after 10 seconds"
   sleep 10
   exit
fi

#echo "using domain $domain for instance $instance"

safe_stop_docker $name

#echo start the waiter...
ruby waiter.rb $instance $domain
#echo waiter done.

echo "`date`: starting new test run with single docker thread instance=$instance domain=$domain country=$country name=$name port=$port proxy=$proxy"

# SIZES info sample
# docker run -d -e SCREEN_WIDTH=1366 -e SCREEN_HEIGHT=768 -e SCREEN_DEPTH=24 -e SCREEN_DPI=74
#selenium/standalone-chrome:4.2.2-20220609
dims=`./getscreendims.sh`
w=`echo $dims|cut -d, -f1`
h=`echo $dims|cut -d, -f2`
echo "`date`: browser dimensions $w,$h"
echo docker run...
docker run -e SCREEN_WIDTH=$w -e SCREEN_HEIGHT=$h \
   --name $name \
   -d \
   --add-host=host.docker.internal:host-gateway \
   -p $port:4444 \
   -v $chromedir:$chromedir \
   --shm-size="1g" \
   selenium/standalone-chrome:latest
echo "`date`: sleep $dsleep for docker to become active"
sleep $dsleep

debug=0
if [ "$instance" -eq "30" ]
then
   debug=1
fi
program="runner.rb"
echo "`date`: starting ruby program=$program port=$port instance=$instance country=$country chromedir=$chromedir debug=$debug ..."
ruby $program $port $instance $domain "$country" $debug
echo "`date`: ruby $program $port done."
safe_stop_docker $name
echo "`date`: test run instance=$instance done."
