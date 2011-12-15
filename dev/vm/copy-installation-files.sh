echo "IP received: $1"

RUBY_STABLE="ruby-1.9.3-p0.tar.gz"

PUPPET_STABLE="puppet-2.7.9.tar.gz"
FACTER_STABLE="facter-1.6.4.tar.gz"
PUPPET_ENVIRONMENT="puppet-installation-environment.sh"

DESTINATION_PATH="root@$1:/root/."

# Check if they already exist?
# if test -f ...
#scp ../ruby-installation/$RUBY_STABLE        $DESTINATION_PATH
scp ../puppet-installation/$PUPPET_STABLE    $DESTINATION_PATH
scp ../puppet-installation/$FACTER_STABLE    $DESTINATION_PATH
scp ./$PUPPET_ENVIRONMENT                    $DESTINATION_PATH
