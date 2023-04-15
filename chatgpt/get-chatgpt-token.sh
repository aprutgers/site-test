#!/bin/sh
cd /home/ec2-user/site-test/chatgpt
echo "doing login to chatgpt and save session token to /tmp/chatgpt_token..."
./login.sh 20 no-proxy > /tmp/chatgpt_out
cat /tmp/chatgpt_out
grep -A 1 __Secure-next-auth.session-token /tmp/chatgpt_out|grep -v __Secure-next-auth.session-token>/tmp/chatgpt_token
/bin/rm -f /tmp/chatgpt_out
echo "done."
