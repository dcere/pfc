echo "IP received: $1"

scp ../ruby-installation/ruby-1.9.3-p0.tar.gz     root@$1:/root/.
scp ../puppet-installation/puppet-2.7.9.tar.gz    root@$1:/root/.
scp ../puppet-installation/facter-1.6.4.tar.gz    root@$1:/root/.
