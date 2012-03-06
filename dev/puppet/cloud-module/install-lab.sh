# Description:
#   Installs the cloud puppet module
#
# Synopsis:
#   install-lab.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: install-lab.sh 155.210.155.170
#
#
# Author:
#   David Ceresuela

NAME="cloud"
PUPPET_DST="/etc/puppet/modules"

SSH="ssh root@$1"

# Create directories
$SSH 'mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}'
$SSH 'mkdir -p $PUPPET_DST/$NAME/lib/puppet/type'
$SSH 'mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME'

# Copy manifests
scp ./manifests/init.pp root@$1:$PUPPET_DST/$NAME/manifests/init.pp
scp ./manifests/term.pp root@$1:$PUPPET_DST/$NAME/manifests/term.pp
scp ./manifests/test.pp root@$1:$PUPPET_DST/$NAME/manifests/test.pp

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

scp $TYPE_SRC/cloud.rb            root@$1:$TYPE_DST/cloud.rb
scp $PROVIDER_SRC/$NAME/cloudp.rb root@$1:$PROVIDER_DST/cloudp.rb

# Copy test
scp ./test.rb root@$1:$PUPPET_DST/$NAME

# Copy validation script
scp ./validate.sh root@$1:$PUPPET_DST/$NAME
