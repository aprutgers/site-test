#!/bin/sh
echo start creating backup-testserver targz...
sudo tar czf /tmp/backup-testserver.gtar \
	/home/ec2-user/site-test \
	/home/ec2-user/psiphon.client.free \
        /tmp/rotated /tmp/*.log
echo done.
