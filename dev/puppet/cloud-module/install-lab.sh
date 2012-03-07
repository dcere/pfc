# Description:
#   Installs the cloud puppet module
#
# Synopsis:
#   install-lab.sh <IP> <files>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:  all the files
#     - man:  only manifests
#     - tp:   only type and provider
#     - test: only test files
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#   _$: install-lab.sh 155.210.155.170 tp
#   _$: install-lab.sh 155.210.155.170 manif
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
if [ $2 = "man" -o $2 = "all" ]
then
   scp ./manifests/init.pp           root@$1:$PUPPET_DST/$NAME/manifests/
   scp ./manifests/term.pp           root@$1:$PUPPET_DST/$NAME/manifests/
   scp ./files/appscale.yaml         root@$1:$PUPPET_DST/$NAME/files/
   scp ./files/appscale-1-node.yaml  root@$1:$PUPPET_DST/$NAME/files/
   scp ./files/mycloud-template.xml  root@$1:$PUPPET_DST/$NAME/files/
fi

if [ $2 = "test" -o $2 = "all" ]
then
   scp ./manifests/test.pp root@$1:$PUPPET_DST/$NAME/manifests/test.pp
fi

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

if [ $2 = "tp" -o $2 = "all" ]
then
   scp $TYPE_SRC/cloud.rb                   root@$1:$TYPE_DST/cloud.rb
   scp $PROVIDER_SRC/$NAME/cloudp.rb        root@$1:$PROVIDER_DST/cloudp.rb
   scp $PROVIDER_SRC/$NAME/appscale_yaml.rb root@$1:$PROVIDER_DST/appscale-yaml.rb
fi

# Copy test
if [ $2 = "test" -o $2 = "all" ]
then
   scp ./test.rb root@$1:$PUPPET_DST/$NAME
fi

# Copy validation script
if [ $2 = "test" -o $2 = "all" ]
then
   scp ./validate.sh root@$1:$PUPPET_DST/$NAME
fi
