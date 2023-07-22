#!/bin/sh
cd /home/ec2-user/site-test
domains="hypercloudzone.com hyperscalercloud.nl pubcloudnews.tech"
for domain in $domains
do
   echo "collecting articles from $domain ..."
   wget -q -O - "https://$domain/feed/" | grep '<link>' | sed 's/<[\/]*link>//g' | sed "s/https\:\/\/$domain\///" | sed 's/^[\s\t]*//'|egrep -v '^http' > $domain/articles
   echo "stored in $domain/articles"
done
