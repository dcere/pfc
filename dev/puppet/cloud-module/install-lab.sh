# Description:
#   Installs the cloud puppet module
#
# Synopsis:
#   install-lab.sh
#
# Arguments:
#   - None.
#
# Examples:
#   _$: install-lab.sh
#
#
# Author:
#   David Ceresuela

NAME="cloud"
PUPPET_DST="/etc/puppet/modules"

# Create directories
mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME

# Copy manifests
cp ./manifests/init.pp $PUPPET_DST/$NAME/manifests/init.pp
cp ./manifests/term.pp $PUPPET_DST/$NAME/manifests/term.pp
cp ./manifests/test.pp $PUPPET_DST/$NAME/manifests/test.pp

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

cp $TYPE_SRC/cloud.rb $TYPE_DST/cloud.rb
cp $PROVIDER_SRC/$NAME/cloudp.rb $PROVIDER_DST/cloudp.rb

# Copy test
cp ./test.rb $PUPPET_DST/$NAME

# Copy validation script
cp ./validate.sh $PUPPET_DST/$NAME
