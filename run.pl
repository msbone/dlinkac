#THE SCRIPT OF ALL SCRIPTS
my $start_run = time();
my $linenr = 0;
my $core = 0;
my $switches;
my $dlink;
use dlink;
use ciscoconf;

my $core1 = ciscoconf->connect(ip => "192.168.1.242",username => "config",password => "<REMOVED>",hostname => "CORE1", enable_password => "<REMOVED>");

print "STARTING \n";
#FIRST LOAD THE FILE WITH ALL THE SWITCHES THAT NEED CONFIG
open (SWITCHES, 'switches.txt');
while (<SWITCHES>) {
$linenr++;
if($linenr == 1) {
#SKIP THE FIRST LINE
}else {
chomp;
$line = $_;
$first = substr($line, 0, 1);
if($first eq "#") {$core++;}else{
$switches++;
my ($name, $port,$vlan, $ip, $gateway) = split(' ', $line, 5);
if($core == 1) {
#CISCO
$core1 -> setvlan(port => $port,vlan => 1337, desc => "CONF MODE");
#WAIT FOR THE CISCO TO DO ITS MAGIC
sleep(35);
#DO THE DLINK MAGIC
$dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => $name);
$dlink->setIP(ip => "10.90.90.90", gateway => "10.90.90.1", subnetmask => "255.255.255.0");
#REMEMBER TO EDIT THIS
$dlink->sendConfig(tftp => "192.168.1.230",file => "config.bin");
sleep(10);
$dlink->close;
undef $dlink;
#Wait for the dlink to restart
sleep(70);
$dlink = dlink->connect(ip => "10.90.90.90",username => "admin",password => "admin", name => $name);
#Will set password here later
$dlink->setIP(ip => $ip, gateway => $gateway, subnetmask => "255.255.255.128");
sleep(5);
$dlink->close;
$core1 -> setvlan(port => $port,vlan => $vlan, desc => $name);

#ADDED SO I CAN TEST IF IT WORKS WITH MORE SWITCHES WITH JUST USING ONE
print "RESET SWITCH AND CHANGE TO NEXT PORT NOW! 80 secounds until it will move right along";
sleep(80);
#WILL RESTART HERE
}
}
}
}

my $end_run = time();
my $run_time = $end_run - $start_run;

print "\n config done for $switches switches in $run_time secounds \n";