<?php
   error_log('start sitetest.php' . "\n");
   $domain = filter_input(INPUT_GET, 'domain', FILTER_SANITIZE_ENCODED);
   # parameter sanity checking...
   if ( $domain == "" ) {
      error_log("domain empty\n");
   }
   error_log("sitetest - domain=$domain\n");
   $data = shell_exec("/home/ec2-user/site-test/sitetest.sh $domain >&1");
   error_log("data=" . $data);
   print $data;
   error_log("sitetest.php done.\n");
?>
