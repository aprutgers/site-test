#!/bin/sh
/home/ec2-user/site-test/collect_stats.sh|tr '\n' '!'|sed 's/\!/<br>/g'>/tmp/stats$$
/home/ec2-user/sendgrid/send_email.sh "site-test stats ts2" /tmp/stats$$
/bin/rm -f /tmp/stats$$
