logfiles='/tmp/test-runner-instance*.log* /tmp/rotated/*'
MAX=${1-25}
echo ""
echo "LATEST ADVERT_CLICK RESULTS($MAX):"
echo ""
data=`zcat -f $logfiles|strings|grep ADVERT_CONVERSION_TITLE|grep -v "=$"|cut -d':' -f 1,2,3,5|sed 's/ADVERT_CONVERSION_TITLE=//'|\
grep -v "Public Cloud News"|\
grep -v "Technisch beleggen"|\
grep -v "Financieel"|\
sort|tail -$MAX|cat -n`
echo "$data"
echo ""
echo DATE COUNTS:
dates=`echo "$data"|awk '{ print $2 }'|sort -u`
for date in $dates
do
   echo -n $date:
   echo "$data"|grep $date|wc -l
done
echo ""

date=`date`
echo ""
echo "===================================================================="
echo                      END REPORT DATE: $date
echo "===================================================================="
