<?php
   error_log('start sitetest.php' . "\n");
   $domain = filter_input(INPUT_GET, 'domain', FILTER_SANITIZE_ENCODED);
   $part   = filter_input(INPUT_GET, 'part',   FILTER_SANITIZE_ENCODED);
   error_log("sitetest - domain='$domain' part='$part'\n");
   $data = shell_exec("/home/ec2-user/site-test/sitetest.sh $domain $part >&1");
   error_log("data=" . $data);
   print $data;
   error_log("sitetest.php done.\n");
?>
