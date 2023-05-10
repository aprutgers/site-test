<?php
   error_log('start sitetest.php' . "\n");
   $action = filter_input(INPUT_GET, 'action', FILTER_SANITIZE_ENCODED);
   $domain = filter_input(INPUT_GET, 'domain', FILTER_SANITIZE_ENCODED);
   $part   = filter_input(INPUT_GET, 'part',   FILTER_SANITIZE_ENCODED);
   $ctr    = filter_input(INPUT_GET, 'ctr',    FILTER_SANITIZE_ENCODED);
   error_log("sitetest - action=$action domain='$domain' part='$part' ctr='$ctr'\n");
   if ($domain == '') {
       $domain = 'all';
   }
   if ($action == '') {
       $action = 'get';
   }
   if ($part == '') {
       $part = '0';
   }
   $shell = "/home/ec2-user/site-test/sitetest.sh $action $domain $part $ctr";
   error_log("shell command='".$shell."'");
   $data = shell_exec($shell . " >&1");
   error_log("data=". $data);
   print $data;
   error_log("sitetest.php done.\n");
?>
