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
PUPPET_DST="/etc/puppet/modules"

# Create directories
sudo mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
sudo mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
sudo mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME

# Copy manifests
sudo cp ./manifests/init.pp      $PUPPET_DST/$NAME/manifests/init.pp
sudo cp ./manifests/term.pp      $PUPPET_DST/$NAME/manifests/term.pp

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

sudo cp $TYPE_SRC/cloud.rb       $TYPE_DST/cloud.rb
sudo cp $PROVIDER_SRC/$NAME/*    $PROVIDER_DST/

# Copy files
sudo cp -r ./files/*     $PUPPET_DST/$NAME/files/

# Copy test
sudo cp ./test.rb    $PUPPET_DST/$NAME
