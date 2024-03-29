#!/bin/sh
hostname=`hostname`
date=`date`
if [ "$1" == "full" ]
then
   logfiles='/nvme/tmp/test-runner-instance*.log* /tmp/rotated/*'
   mode='FULL'
else
   logfiles='/nvme/tmp/test-runner-instance*.log*'
   mode='DAY'
fi
if [ "$1" == "history" ]
then
    date="$2"
    logfiles="/tmp/rotated/*test-runner-instance*.log-$date.gz"
    mode='DAY'
fi
echo "===================================================================="
echo                      START REPORT DATE: $date - $mode
echo "===================================================================="
echo ""

TOTAL_PAGE_LOADS=`zcat -f $logfiles|strings|grep -i 'safe_get_url: url='|wc -l`
echo TOTAL_PAGE_LOADS: $TOTAL_PAGE_LOADS

DOMAINS=`cat /home/ec2-user/site-test/domains|grep -v ,30,|awk -F: '{ print $1 "|"}'|tr -d "\n"|sed 's/|$//'`
DOMAIN_PAGE_LOADS=`zcat -f $logfiles|strings|grep -i 'safe_get_url: url='|egrep "$DOMAINS"|grep -v google.com|wc -l`
echo DOMAIN_PAGE_LOADS: $DOMAIN_PAGE_LOADS

DOMAIN_PAGE_LOAD_RATIO=`echo "scale=2;100 * $DOMAIN_PAGE_LOADS / $TOTAL_PAGE_LOADS" | bc -l`
echo "DOMAIN_PAGE_LOAD_RATIO: $DOMAIN_PAGE_LOAD_RATIO%"

# break out per domain
if [ "$mode" == "DAY" ]
then
   echo "BREAKOUT:"
   LIST_DOMAINS=`cat /home/ec2-user/site-test/domains|grep -v ,30,|egrep -v ":$"|awk -F: '{ print $1}'`
   #echo LIST_DOMAINS=$LIST_DOMAINS
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

INTERCEPTED_COUNT=`zcat -f $logfiles|strings|grep -v get_consent_button|grep -i intercepted|wc -l`
echo "INTERCEPTED: $INTERCEPTED_COUNT"

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
AD_ZERO_FOUND_COUNT=`zcat -f $logfiles|strings|grep "going to click"|grep "0 found"|wc -l`
AD_ZERO_FOUND_PCT=`echo "scale=2;100 * $AD_ZERO_FOUND_COUNT / $AD_FOUND_COUNT" | bc -l`
AD_NON_ZERO_FOUND_COUNT=`zcat -f $logfiles|strings|grep "going to click"|grep -v "0 found"|wc -l`
AD_NON_ZERO_FOUND_PCT=`echo "scale=2;100 * $AD_NON_ZERO_FOUND_COUNT / $AD_FOUND_COUNT" | bc -l`
echo "AD_FOUND_COUNT: $AD_FOUND_COUNT"
echo "AD_ZERO_FOUND_COUNT: $AD_ZERO_FOUND_COUNT ($AD_ZERO_FOUND_PCT)%"
echo "AD_NON_ZERO_FOUND_COUNT: $AD_NON_ZERO_FOUND_COUNT ($AD_NON_ZERO_FOUND_PCT%)"

WORDPRESS_DB_ERR=`zcat -f $logfiles -f|strings|grep -i "title=Database Error"|wc -l`
echo "WORDPRESS_DB_ERR: $WORDPRESS_DB_ERR"

NETWORK_ERRORS=`zcat -f $logfiles|strings|grep -i ERR_CONN|wc -l`
echo "NETWORK_ERRORS: $NETWORK_ERRORS"

TIMEOUT_ERRORS=`zcat -f $logfiles -f|strings|grep -i Net::ReadTimeout|wc -l`
echo "TIMEOUT_ERRORS: $TIMEOUT_ERRORS (Net::ReadTimeout)"

DOCKER_RUNS=`zcat -f $logfiles -f|strings|grep -i 'docker run'|wc -l`
echo "DOCKER_RUNS: $DOCKER_RUNS"

LOST_CONTAINERS=`zcat -f $logfiles -f|strings|egrep -i "Cannot kill container| No such container"|wc -l`
echo "LOST_CONTAINERS: $LOST_CONTAINERS (is not running err)"

DOCKER_FAIL_ERRORS=`zcat -f $logfiles -f|strings|grep -i "FAIL"|wc -l`
echo "DOCKER_FAIL_ERRORS: $DOCKER_FAIL_ERRORS"

DOCKER_MEM_BAIL=`zcat -f $logfiles -f|strings|grep -i "MEMORY BAIL"|wc -l`
echo "DOCKER_MEM_BAIL: $DOCKER_MEM_BAIL"

DOCKER_ERROR_RATE=`echo "scale=2;100 * ( $DOCKER_FAIL_ERRORS + $DOCKER_MEM_BAIL) / $DOCKER_RUNS" | bc -l`
echo "DOCKER_ERROR_RATE: $DOCKER_ERROR_RATE %"

# indirect errors from chrome driverr related to memory shortages/slow swap issues
MEM_ERRORS="page crash|invalid session id|cannot determine loading status|not connected to DevTools|Unable to receive message from renderer|title=Database Error"

CHROME_MEM_ERRORS=`zcat -f $logfiles -f|strings|egrep -i "$MEM_ERRORS"|wc -l`
echo "CHROME_MEM_ERRORS: $CHROME_MEM_ERRORS (memory/swap related)"

DOCKER_ECF_ERRORS=`zcat -f $logfiles -f|strings|grep -i "Errno::ECONNREFUSED"|wc -l`
echo "DOCKER_ECF_ERRORS: $DOCKER_ECF_ERRORS (Errno::ECONNREFUSED)"

DOCKER_EOF_ERRORS=`zcat -f $logfiles -f|strings|grep -i "EOFError"|wc -l`
echo "DOCKER_EOF_ERRORS: $DOCKER_EOF_ERRORS (EOFError)"

CHROME_DRIVER_ERRORS=`zcat -f $logfiles -f|strings|egrep -i "DriverServiceSessionFactory|DevToolsActivePort"|wc -l`
echo "CHROME_DRIVER_ERRORS: $CHROME_DRIVER_ERRORS (DriverServiceSessionFactory)"

CONNECTION_CLOSED_ERRORS=`zcat -f $logfiles -f|strings|grep -i "ERR_CONNECTION_CLOSED"|wc -l`
echo "CONNECTION_CLOSED_ERRORS: $CONNECTION_CLOSED_ERRORS (Selenium::WebDriver::Error)"

# Failing PSI proxies
PSI_PROXYFAIL=`zcat -f $logfiles -f|strings|grep "proxy not working ok" |wc -l`
echo "PSI_PROXYFAIL: $PSI_PROXYFAIL"

# 403 errors when we are blocking ourselfs with blacklisting on nginx
HTTP_FORBIDDEN=`zcat -f $logfiles -f|strings|grep safe_get_url|grep Forbidden|wc -l`
echo "HTTP_FORBIDDEN: $HTTP_FORBIDDEN"
zcat -f $logfiles -f|strings|grep safe_get_url|grep Forbidden

UNKOWN_EXPR="ERR_CONN|ReadTimeout|NoSuchElementError|ElementNotInteractableError|ignored|StaleElementReferenceError|intercepted|ECONNREFUSED|too many timeouts|EOFError|DriverServiceSessionFactory|DevToolsActivePort|FAIL|MEMORY BAIL|$MEM_ERRORS|Cannot kill container|No such container|Azure error"

UNKOWN_ERRORS=`zcat -f $logfiles|grep -i error|egrep -iv "$UNKOWN_EXPR"|wc -l`
echo "UNKNOWN_ERRORS: $UNKOWN_ERRORS"

if [ "$UNKOWN_ERRORS" -ge 0 ]
then
   zcat -f $logfiles -f|grep -i error|egrep -iv "$UNKOWN_EXPR"
fi

# extra analytics data for CPU core, NVME and SSD drive
if [ "$hostname" == "centos9server" ]
then
   CPU_CORE_TEMP=`sensors -u|grep -A 1 'Package id 0'|tail -1|awk '{ print $2 }'`
   echo "CPU_CORE_TEMP: $CPU_CORE_TEMP"
   CPU_FREQ=`sudo cpupower monitor|head -3|tail -1|cut -d'|' -f9`
   echo "CPU_FREQ: $CPU_FREQ (MHz)"
   SSD_WEAR_LEVEL_COUNT=`sudo smartctl /dev/sda  -ia|grep "Wear_Leveling_Count"|awk '{ print $4}'`
   echo "SSD_WEAR_LEVEL: $SSD_WEAR_LEVEL_COUNT"
   SSD_TEMP=`sudo smartctl /dev/sda -ia|grep "Temperature_Celsius"|awk '{ print $4}'`
   echo "SSD_TEMP: $SSD_TEMP"
   NVME_TMP_USED=`df /nvme/tmp|grep -v Use|awk '{ print $5 }'`
   echo "NVME_TMP_USED: $NVME_TMP_USED"
   NVME_TEMP=`sudo smartctl -a /dev/nvme0n1| grep "Temperature:"|awk '{ print $2}'`
   echo "NVME_TEMP: $NVME_TEMP"
fi

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
