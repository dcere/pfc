# Description:
#   Configures puppet
#
# Synopsis:
#   puppet-configuration.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: ./puppet-configuration.sh
#
#
# Author:
#   David Ceresuela

# Create configuration file
puppetmasterd --genconfig > /etc/puppet/puppet.conf

# Create manifests directory and site.pp file
mkdir -p /etc/puppet/manifests
touch /etc/puppet/manifests/site.pp

# Create user and group
groupadd puppet
useradd -g puppet puppet

# Change /var/lib/puppet/rrd permissions
chown puppet /var/lib/puppet/rrd
chgrp puppet /var/lib/puppet/rrd

# Test installation
puppet apply ./configuration-manifest.pp

# Change /var/lib/puppet/rrd permissions
chown puppet /var/lib/puppet/rrd
chgrp puppet /var/lib/puppet/rrd
