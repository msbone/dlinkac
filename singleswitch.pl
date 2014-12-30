#!/usr/bin/perl -w
use dlink;
use ciscoconf;
use stuff;
# (1) quit unless we have the correct number of command-line args
$num_args = $#ARGV + 1;
if ($num_args != 3) {
  print "\nUsage: singleswitch.pl ip_address subnetmask new_password \n";
  exit;
}

print "\n Make sure the switch is in factory settings and you are in correct network (10.90.90.90/24) \n Press enter to start \n";
<STDIN>;
print "We will start to ping 10.90.90.90 \n";
$respond = stuff->ping(ip => "192.168.1.1",tryes => "5");

if ($respond == 0)
{
  print "No able to ping 10.90.90.90, check your connection \n";
} else {
  print "Responds to ping, all good so far \n";
}
