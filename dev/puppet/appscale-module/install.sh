# Description:
#   Installs the appscale puppet module
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

NAME="appscale"
PUPPET_DST="/etc/puppet/modules"

# Create directories
sudo mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
sudo mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
sudo mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME

# Copy manifests
sudo cp ./manifests/init.pp      $PUPPET_DST/$NAME/manifests/init.pp
sudo cp ./manifests/stop.pp      $PUPPET_DST/$NAME/manifests/stop.pp

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

sudo cp $TYPE_SRC/appscale.rb                $TYPE_DST/appscale.rb
sudo cp $PROVIDER_SRC/$NAME/appscalep.rb     $PROVIDER_DST/appscalep.rb

# Copy files
sudo cp -r ./files/*     $PUPPET_DST/$NAME/files/

# Copy test
sudo cp ./test.rb    $PUPPET_DST/$NAME
