#!/bin/sh
/home/ec2-user/site-test/collect_stats.sh|tr '\n' '!'|sed 's/\!/<br>/g'>/tmp/stats$$
echo disabled email site-test stats
#/home/ec2-user/sendgrid/send_email.sh "site-test stats" /tmp/stats$$
/bin/rm -f /tmp/stats$$
