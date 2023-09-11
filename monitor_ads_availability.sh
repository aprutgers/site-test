#!/bin/sh
DOMAINS=`shuf /home/ec2-user/site-test/domains|grep -v ,30,|egrep -v ":$"|awk -F: '{ print $1}'`
BODY=/tmp/ana-runner-body.txt
LOG=/tmp/ana-runner.log
cd /home/ec2-user/site-test
for domain in $DOMAINS
do
   echo "`date`: checking domain $domain ..."
   cat domains.templ|sed "s/@@ANA_DOMAIN@@/$domain/" > domains
   /home/ec2-user/site-test/ana-runner.sh > $LOG 2>&1
   if egrep 'get_target_links: found [1-5] targets' $LOG
   then
      subject="ALERT: Target Ads Found on $domain"
      echo "`date`: $subject" 
      egrep 'get_target_links: found [1-5] targets' $LOG > $BODY
      /home/ec2-user/sendgrid/send_email.sh "$subject" $BODY $LOG
   else
      echo "`date`: INFO: NO Target Ads Found on $domain" 
   fi
   sleep=$((RANDOM % 30))
   echo "`date`: sleep $sleep"
   sleep $sleep
   echo "`date`: checking domain $domain done."
   /bin/rm -f $LOG $BODY
done
