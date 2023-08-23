#!/bin/sh
date=`date '+%Y%m%d'`
file=/home/ec2-user/site-test/stats/stats.$date
echo "`date`: creating $file"
/home/ec2-user/site-test/collect_stats.sh>$file
errors=`grep UNKNOWN_ERRORS $file | awk '{ print $2 }'`
if [ "$errors" -ge "0" ]
then
    echo "`date`: found $errors unknown errors, send alert e-mail"
    /home/ec2-user/bin/send-email.sh "ALERT: site-test unknown errors" $file $file
else
    echo "`date`: no unknown errors found"
fi
echo "`date`: done"
