# Some constants

VIRSH_CONNECT = "virsh -c qemu:///system"
MY_IP = Facter.value(:ipaddress)
PING = "ping -q -c 1 -w 4"
DOMAINS_FILE = "/tmp/defined-domains" # resource[:name] cannot be used at this point
CRON_FILE = "/var/spool/cron/crontabs/root"
