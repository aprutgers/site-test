#!/bin/sh
w=`awk -v min=600 -v max=1366 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
h=`awk -v min=320 -v max=768  'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
echo "$w,$h"
