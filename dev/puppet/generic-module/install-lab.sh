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

NAME="generic-module"
PUPPET_DST="/etc/puppet/modules"

SSH="ssh root@$1"

# Create directories
$SSH mkdir -p $PUPPET_DST/$NAME/{type,provider}

# Copy files
#scp ./type/*         root@$1:$PUPPET_DST/$NAME/type/         
scp ./provider/*     root@$1:$PUPPET_DST/$NAME/provider/
