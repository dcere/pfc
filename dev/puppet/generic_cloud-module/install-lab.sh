# Description:
#   Installs the generic puppet module
#
# Synopsis:
#   install-lab.sh <IP> <files>
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

if [ $# -ne 1 ]
then
   echo "Use: $0 <IP address>"
   echo "Examples
$0 155.210.155.170
"
   exit 1
fi 


# Copy type and provider
SSH="ssh root@$1"
NAME="generic_cloud"
PUPPET_DST="/etc/puppet/modules"
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

$SSH mkdir -p $PUPPET_DST/$NAME/{files,manifests}
$SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
$SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME

scp $TYPE_SRC/generic_cloud.rb      root@$1:$TYPE_DST/generic_cloud.rb

# All provider files
scp -r $PROVIDER_SRC/$NAME/*        root@$1:$PROVIDER_DST/

# All files files
scp -r ./files/*     root@$1:$PUPPET_DST/$NAME/files/

# All manifests
scp -r ./manifests/*     root@$1:$PUPPET_DST/$NAME/manifests/
