#!/bin/sh
grep -B +2 Forbidden /mnt/tmp/test-runner-instance*.log|grep 2022|awk -F/ '{ print $10 }'
