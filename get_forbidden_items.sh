#!/bin/sh
grep -B +2 Forbidden /nvme/tmp/test-runner-instance*.log|grep 2022|awk -F/ '{ print $10 }'
