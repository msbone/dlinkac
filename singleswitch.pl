#!/usr/bin/perl -w
use dlink;
use ciscoconf;
use stuff;
use Net::Netmask;

# (1) quit unless we have the correct number of command-line args
$num_args = $#ARGV + 1;
if ($num_args != 2) {
  print "\nUsage: singleswitch.pl ip_address/cidr new_password  \n";
  exit;
}

$ip_address=$ARGV[0];
$password=$ARGV[2];

$nett = new Net::Netmask ($ip_address);

$netmask = $nett->mask();
$gateway = $net->nth(1);

print "\n To use this script your machine must have the IP 10.90.90.91/24 \n";
print "Make sure the switch is in factory settings and is done with boot \n Press enter to start \n";
<STDIN>;
print "We will start to ping 10.90.90.90 \n";
$respond = stuff->ping(ip => "10.90.90.90",tryes => "5");

if ($respond == 0)
{
  print "No able to ping 10.90.90.90, check your connection \n";
  exit;
}
  print "Responds to ping, all good \n";
  #DO THE DLINK MAGIC
  $dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => " ");
  $dlink->setIP(ip => "10.90.90.90", gateway => "10.90.90.91", subnetmask => "255.255.255.0");
  #REMEMBER TO EDIT THIS
  $dlink->sendConfig(tftp => "10.90.90.91",file => "config.bin");
  sleep(10);
  $dlink->close;
  undef $dlink;

  print "The switch should now reboot, lets wait \n";
  sleep(3);
  $respond = stuff->ping(ip => "10.90.90.90",tryes => "120");

  if ($respond == 0)
  {
    print "No able to ping 10.90.90.90, the switch is not up after config push, \n";
    exit;
  }
  print "Switch is back online, we now set password then new IP";
  $dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => " ");
  $dlink->setPassword(password => $password);
  sleep(2);
  $dlink->setIP(ip => $ip_address, gateway => $gateway, subnetmask => $subnetmask);
  sleep(2);
  $dlink->close;
