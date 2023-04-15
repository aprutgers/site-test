#!/bin/sh

instance=$1
dsleep=5
port=$(( 5000 + $instance))
name="run$port"

safe_stop_docker() {
   name="$1"
   id=`docker ps -a|grep $name|awk '{print $1}'`
   if [ ! -z "$id" ]
   then
      echo "docker kill $name - $id"
      docker kill $id
      docker rm $id
   else
     echo "docker $name not running"
   fi
}

safe_stop_docker $name

echo "starting new test run with single docker thread instance=$instance name=$name port=$port"

echo docker run...
docker run \
   --name $name \
   -d \
   --add-host=host.docker.internal:host-gateway \
   -p $port:4444 \
   --shm-size="2g" \
   selenium/standalone-chrome:latest
echo docker sleep $dsleep
sleep $dsleep

program="detect.rb"
echo starting ruby program=$program port=$port instance=$instance ...
ruby $program $port $instance
echo ruby $program $port done.
safe_stop_docker $name
echo test run instance=$instance done. 
