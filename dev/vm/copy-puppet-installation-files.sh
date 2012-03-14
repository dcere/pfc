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

DESTINATION_PATH="root@$1:/root/."

# Check if they already exist?
# if test -f ...
#scp ../ruby-installation/$RUBY_STABLE            $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_STABLE        $DESTINATION_PATH
scp ../puppet-installation/$FACTER_STABLE        $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_INSTALL       $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_ENVIRONMENT   $DESTINATION_PATH
