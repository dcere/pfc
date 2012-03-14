# Description:
#   Installs puppet
#
# Synopsis:
#   puppet-installation.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: ./puppet-installation.sh
#
#
# Author:
#   David Ceresuela

PUPPET_STABLE="puppet-2.7.9"
FACTER_STABLE="facter-1.6.4"

./puppet-installation-environment.sh

tar xf "$FACTER_STABLE.tar.gz"
rm "$FACTER_STABLE.tar.gz"
cd ./$FACTER_STABLE
./install.rb
cd ../

tar xf "$PUPPET_STABLE.tar.gz"
rm "$PUPPET_STABLE.tar.gz"
cd ./$PUPPET_STABLE
./install.rb
cd ../

# Mini test
facter
