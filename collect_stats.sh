#!/bin/sh
hostname=`hostname`
if [ "$1" == "full" ]
then
   logfiles='/mnt/tmp/test-runner-instance*.log* /tmp/rotated/*'
   mode='FULL'
else
   logfiles='/mnt/tmp/test-runner-instance*.log*'
   mode='DAY'
fi
date=`date`
echo "===================================================================="
echo                      START REPORT DATE: $date - $mode
echo "===================================================================="
echo ""

TOTAL_PAGE_LOADS=`zcat -f $logfiles|strings|grep -i 'safe_get_url: url='|wc -l`
echo TOTAL_PAGE_LOADS: $TOTAL_PAGE_LOADS

DOMAINS=`cat /home/ec2-user/site-test/domains|grep -v ,20,|awk -F: '{ print $1 "|"}'|tr -d "\n"|sed 's/|$//'`
DOMAIN_PAGE_LOADS=`zcat -f $logfiles|strings|grep -i 'safe_get_url: url='|egrep "$DOMAINS"|grep -v google.com|wc -l`
echo DOMAIN_PAGE_LOADS: $DOMAIN_PAGE_LOADS

DOMAIN_PAGE_LOAD_RATIO=`echo "scale=2;100 * $DOMAIN_PAGE_LOADS / $TOTAL_PAGE_LOADS" | bc -l`
echo "DOMAIN_PAGE_LOAD_RATIO: $DOMAIN_PAGE_LOAD_RATIO%"

# break out per domain
if [ "$mode" == "DAY" ]
then
   echo "BREAKOUT:"
   LIST_DOMAINS=`cat /home/ec2-user/site-test/domains|grep -v ,20,|egrep -v ":$"|awk -F: '{ print $1}'`
   for domain in $LIST_DOMAINS
   do
      SPLIT_DOMAIN_PAGE_LOADS=`zcat -f $logfiles|strings|grep -i 'safe_get_url: url='|grep "$domain"|grep -v google.com|wc -l`
      SPLIT_DOMAIN_PAGE_LOAD_RATIO=`echo "scale=2;100 * $SPLIT_DOMAIN_PAGE_LOADS / $DOMAIN_PAGE_LOADS" | bc -l`
      echo "   $domain: $SPLIT_DOMAIN_PAGE_LOADS (${SPLIT_DOMAIN_PAGE_LOAD_RATIO}%)"
   done
   echo ""
fi

NO_SEARCH_RESULTS=`zcat -f $logfiles|strings|grep -i "could not locate a target link"|wc -l`
echo NO SEARCH RESULTS: $NO_SEARCH_RESULTS

SEARCH_CLICKS=`zcat -f $logfiles|strings|grep -i SEARCH_CLICK_TITLE|wc -l`
echo SEARCH CLICKS: $SEARCH_CLICKS

AD_CLICKS=`zcat -f $logfiles|strings|grep -i ADVERT_CONVERSION_TITLE| wc -l`
echo ADVERT CLICKS: $AD_CLICKS

AD_CLICK_COUNT_OK=`zcat -f $logfiles|strings|grep ADVERT_CONVERSION_TITLE|cut -d: -f 1,3,5| \
grep -v "Public Cloud News"|\
grep -v "Technisch beleggen"|\
wc -l`
echo "AD_CLICK_COUNT_OK: $AD_CLICK_COUNT_OK"

OKR=`echo "scale=2;100 * $AD_CLICK_COUNT_OK / $AD_CLICKS" | bc -l`
echo "AD_CLICK_OK_RATE: $OKR %"

CTR=`echo "scale=2;100 * $AD_CLICK_COUNT_OK / $DOMAIN_PAGE_LOADS" | bc -l`
echo "DOMAIN_CLICK_TROUGH_RATE: $CTR % (CTR)"

# zero v.s. non zero ad links found
AD_FOUND_COUNT=`zcat -f $logfiles|strings|grep "going to click"|wc -l`
echo "AD_FOUND_COUNT: $AD_FOUND_COUNT"
AD_ZERO_FOUND_COUNT=`zcat -f $logfiles|strings|grep "going to click"|grep "0 found"|wc -l`
AD_ZERO_FOUND_PCT=`echo "scale=2;100 * $AD_ZERO_FOUND_COUNT / $AD_FOUND_COUNT" | bc -l`
echo "AD_ZERO_FOUND_COUNT: $AD_ZERO_FOUND_COUNT ($AD_ZERO_FOUND_PCT)%"
AD_NON_ZERO_FOUND_COUNT=`zcat -f $logfiles|strings|grep "going to click"|grep -v "0 found"|wc -l`
AD_NON_ZERO_FOUND_PCT=`echo "scale=2;100 * $AD_NON_ZERO_FOUND_COUNT / $AD_FOUND_COUNT" | bc -l`
echo "AD_NON_ZERO_FOUND_COUNT: $AD_NON_ZERO_FOUND_COUNT ($AD_NON_ZERO_FOUND_PCT%)"

DOCKER_RUNS=`zcat -f $logfiles -f|strings|grep -i 'docker run...$'|wc -l`
echo "DOCKER_RUNS: $DOCKER_RUNS"

NETWORK_ERRORS=`zcat -f $logfiles|strings|grep -i ERR_CONN|wc -l`
echo "NETWORK_ERRORS: $NETWORK_ERRORS"

TIMEOUT_ERRORS=`zcat -f $logfiles -f|strings|grep -i Net::ReadTimeout|wc -l`
echo "TIMEOUT_ERRORS: $TIMEOUT_ERRORS (Net::ReadTimeout)"

DOCKER_ERRORS=`zcat -f $logfiles -f|strings|grep -i "Errno::ECONNREFUSED"|wc -l`
echo "DOCKER_ERRORS: $DOCKER_ERRORS (Errno::ECONNREFUSED)"

DOCKER_EOF_ERRORS=`zcat -f $logfiles -f|strings|grep -i "EOFError"|wc -l`
echo "DOCKER_EOF_ERRORS: $DOCKER_EOF_ERRORS (EOFError)"

CHROME_DRIVER_ERRORS=`zcat -f $logfiles -f|strings|egrep -i "DriverServiceSessionFactory|DevToolsActivePort"|wc -l`
echo "CHROME_DRIVER_ERRORS: $CHROME_DRIVER_ERRORS (DriverServiceSessionFactory)"

UNKOWN_ERRORS=`zcat -f $logfiles -f|grep -i error|grep -v ReadTimeout|grep -v NoSuchElementError|grep -v ElementNotInteractableError|grep -v ignored|grep -v StaleElementReferenceError|grep -v intercepted|grep -v ECONNREFUSED|grep -v 'too many timeouts'|grep -v "EOFError"|grep -v "DriverServiceSessionFactory"|grep -v "DevToolsActivePort"|wc -l`
echo "UNKNOWN_ERRORS: $UNKOWN_ERRORS"

if [ "$UNKOWN_ERRORS" -ge 0 ]
then
   zcat -f $logfiles -f|grep -i error|grep -v ReadTimeout|grep -v NoSuchElementError|grep -v ElementNotInteractableError|grep -v ignored|grep -v StaleElementReferenceError|grep -v intercepted|grep -v ECONNREFUSED|grep -v 'too many timeouts'|grep -v "EOFError"|grep -v "DriverServiceSessionFactory"|grep -v "DevToolsActivePort"
fi


if [ "$1" == "detail" ]
then
   zcat -f $logfiles -f|grep -i error|grep -v ReadTimeout|grep -v NoSuchElementError|grep -v ElementNotInteractableError|grep -v ignored|grep -v StaleElementReferenceError|grep -v intercepted|grep -v ECONNREFUSED|grep -v 'too many timeouts'|grep -v "EOFError"
fi

DER=`echo "scale=2;100 * $DOCKER_ERRORS / $DOCKER_RUNS" | bc -l`
echo "DOCKER_ERRATE: $DER %"

# 403 errors when we are blocking ourselfs with blacklisting on nginx
FORBIDDEN=`zcat -f $logfiles -f|strings|grep safe_get_url|grep Forbidden|wc -l`
echo "FORBIDDEN: $FORBIDDEN"
zcat -f $logfiles -f|strings|grep safe_get_url|grep Forbidden

# extra analytics data for local hardware
if [ "$hostname" == "centos9server" ]
then
   # SSD status
   SSD_WEAR_LEVEL_COUNT=`sudo smartctl  /dev/sda -ia|grep "Wear_Leveling_Count"|awk '{ print $4}'`
   echo "SSD_WEAR_LEVEL: $SSD_WEAR_LEVEL_COUNT (084p)"
   SSD_TEMP=`sudo smartctl  /dev/sda -ia|grep "Temperature_Celsius"|awk '{ print $4}'`
   echo "SSD_TEMP: $SSD_TEMP"

   # MNT-TMP used/free space
   MNT_TMP_USED=`df /mnt/tmp|grep -v Use|awk '{ print $5 }'`
   echo "MNT_TMP_USED: $MNT_TMP_USED"
fi

# Failing PSI proxies
PROXYFAIL=`zcat -f $logfiles -f|strings|grep "proxy not working ok" |wc -l`
echo "PROXYFAIL: $PROXYFAIL"

MAX=20

echo ""
echo "LATEST ADVERT_CLICK RESULTS($MAX):"
echo ""
data=`zcat -f $logfiles|strings|grep ADVERT_CONVERSION_TITLE|cut -d':' -f 1,2,3,5|sed 's/ADVERT_CONVERSION_TITLE=//'|\
grep -v "Public Cloud News"|\
grep -v "Technisch beleggen"|\
grep -v "Financieel"|\
sort|tail -$MAX|cat -n`
echo "$data"
echo ""
date=`date`
echo ""
echo "===================================================================="
echo                      END REPORT DATE: $date
echo "===================================================================="
