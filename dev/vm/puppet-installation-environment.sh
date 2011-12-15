# Run as . ./puppet-installation-environment.sh

if [ $1 = "--help" ]
then
  echo "Run as: . $0"
fi


# Stable releases!!
FACTER_DIR="/root/facter-1.6.4"
PUPPET_DIR="/root/puppet-2.7.9"

# Values from http://docs.puppetlabs.com/guides/from_source.html
# PATH=$PATH:$SETUP_DIR/facter/bin:$SETUP_DIR/puppet/bin
# RUBYLIB=$SETUP_DIR/facter/lib:$SETUP_DIR/puppet/lib

PATH=$PATH:$FACTER_DIR/bin:$PUPPET_DIR/puppet/bin
RUBYLIB=$FACTER_DIR/lib:$PUPPET_DIR/lib

export PATH RUBYLIB
