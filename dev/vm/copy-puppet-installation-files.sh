# Description:
#   Copies puppet installation files from host to remote host on <IP> address.
#
# Synopsis:
#   copy-puppet-installation-files.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: copy-puppet-installation-files.sh 192.168.1.100
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -eq 0 ]
then
  echo "You must supply a valid IP:"
  echo "  $0 <IP> "
  exit 1
fi

# Copy files
echo "IP received: $1"

RUBY_STABLE="ruby-1.9.3-p0.tar.gz"

PUPPET_STABLE="puppet-2.7.9.tar.gz"
FACTER_STABLE="facter-1.6.4.tar.gz"
PUPPET_ENVIRONMENT="puppet-installation-environment.sh"
PUPPET_INSTALL="puppet-installation.sh"
PUPPET_CONFIGURE="puppet-configuration.sh"
CONF_MANIFEST="configuration-manifest.pp"

DESTINATION_PATH="root@$1:/root/."

# Copy files
scp ../puppet-installation/$PUPPET_STABLE          $DESTINATION_PATH
scp ../puppet-installation/$FACTER_STABLE          $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_INSTALL         $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_ENVIRONMENT     $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_CONFIGURE       $DESTINATION_PATH
scp ../puppet-installation/$CONF_MANIFEST          $DESTINATION_PATH
