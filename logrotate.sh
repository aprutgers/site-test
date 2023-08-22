#!/bin/sh
cd /mnt/tmp
logfiles=`ls -1 test-runner-instance*.log`
cd /tmp
ts=`date +%Y%m%d`
echo rotating $logfiles
for file in $logfiles
do
   echo rotate $file
   rfile="/tmp/rotated/$file-$ts"
   echo rotated-file: $rfile
   if [ -f "$rfile.gz" ]
   then
      echo "$rfile.gz exists no rotation needed"
   else
      echo rotating $file...
      cp "/nvme/tmp/$file" "$rfile"
      gzip $rfile
      # truncate
      cp /dev/null "/nvme/tmp/$file"
      echo rotating done.
   fi
done
