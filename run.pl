#!/usr/bin/perl -w
use dlink;
use ciscoconf;
use stuff;
use Net::Netmask;
use DBI;

require "/lcs/config.pm";

#THE SCRIPT OF ALL SCRIPTS
$dbh = DBI->connect("dbi:mysql:$lcs::config::db_name",$lcs::config::db_username,$lcs::config::db_password) or die "Connection Error: $DBI::errstr\n";
$sql = "select netlist.subnet, netlist.id AS netid, switches.*, coreswitches.name AS distroname, coreswitches.model AS distromodel, coreswitches.ip as distroip from switches JOIN coreswitches, netlist WHERE netlist.id = switches.net_id AND switches.distro_id = coreswitches.id AND switches.model = 'dgs24' AND switches.configured = 0";

$sth = $dbh->prepare($sql);
$sth->execute or die "SQL Error: $DBI::errstr\n";

while (my $ref = $sth->fetchrow_hashref()) {


  $distro_name = $ref->{'distroname'};
  $distro_model = $ref->{'distromodel'};
  $distro_ip = $ref->{'distroip'};

  $connected_port = $ref->{'distro_port'};

  if($distro_model eq "3560g") {
    my $distro = ciscoconf->connect(ip => $distro_ip,username => $lcs::config::ios_user,password => $lcs::config::ios_pass,hostname => $distro_name, enable_password => $lcs::config::ios_pass);
    $distro -> setup_port(port => $connected_port);

    print "We will start to ping 10.90.90.90 \n";
    $respond = stuff->ping(ip => "10.90.90.90",tryes => "20");

    if ($respond == 0)
    {
      print "No able to ping 10.90.90.90, check your connection \n";
      exit;
    }
    #DO THE DLINK MAGIC
    $dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => $ref->{'name'});
    sleep(1);
    $dlink->setIP(ip => "10.90.90.90", gateway => "10.90.90.1", subnetmask => "255.255.255.0");
    #REMEMBER TO EDIT THIS
    sleep(1);
    $dlink->sendConfig(tftp => $lcs::config::tftp_ip,file => "config.bin");
    sleep(5);
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
    print "Switch is back online, we now set password then new IP \n";
    $dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => $ref->{'name'});
    $dlink->setPassword(password => $lcs::config::dlink_pass);
    sleep(2);

    $cidr = $ref->{'ip'}." ".$ref->{'subnet'};
    $block = new Net::Netmask ($cidr);

    $dlink->setIP(ip => $ref->{'ip'}, gateway => $block->nth(1), subnetmask => $block->mask());
    sleep(2);
    $dlink->close;

    $distro -> setvlan(port => $connected_port,vlan => $vlan, desc => $ref->{'name'});
    $distro -> exit();
    undef $distro;
  }
}
