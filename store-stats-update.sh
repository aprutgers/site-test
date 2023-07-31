#!/bin/sh
date=`date '+%Y%m%d'`
echo "`date`: creating /home/ec2-user/site-test/stats/stats.$date"
/home/ec2-user/site-test/collect_stats.sh>/home/ec2-user/site-test/stats/stats.$date
echo "`date`: done"
