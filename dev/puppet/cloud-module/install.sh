# Description:
#   Installs the cloud puppet module
#
# Synopsis:
#   install.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: install.sh
#
#
# Author:
#   David Ceresuela

NAME="cloud"

# Create directories
sudo mkdir -p /etc/puppet/modules/$NAME/{files,templates,manifests}
sudo mkdir -p /etc/puppet/modules/$NAME/lib/puppet/type
sudo mkdir -p /etc/puppet/modules/$NAME/lib/puppet/provider/$NAME

# Copy manifest
sudo cp ./manifests/init.pp /etc/puppet/modules/$NAME/manifests/init.pp

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="/etc/puppet/modules/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="/etc/puppet/modules/$NAME/lib/puppet/provider/$NAME"
sudo cp $TYPE_SRC/cloud.rb $TYPE_DST/cloud.rb
sudo cp $PROVIDER_SRC/$NAME/cloudp.rb $PROVIDER_DST/cloudp.rb

# Copy test
PUPPET_DST="/etc/puppet/"
sudo cp ./test.rb $PUPPET_DST/modules/$NAME
