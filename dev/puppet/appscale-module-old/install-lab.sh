# Description:
#   Installs the appscale puppet module
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
#     - app:  AppScale local manifests
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#   _$: install-lab.sh 155.210.155.170 tp
#   _$: install-lab.sh 155.210.155.170 manif
#
#
# Author:
#   David Ceresuela

if [ $# -ne 2 ]
then
   echo "Use: $0 <IP address> <set of files>"
   echo "Examples
$0 155.210.155.170 all
$0 155.210.155.170 tp
"
   exit 1
fi 

NAME="appscale"
PUPPET_DST="/etc/puppet/modules"

SSH="ssh root@$1"

# Create directories
#if [ $2 != "app" -o $2 != "web" -o $2 != "jobs" ]
#then
   $SSH mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME
#fi

# Copy manifests
if [ $2 = "man" -o $2 = "all" ]
then
   scp ./manifests/init.pp    root@$1:$PUPPET_DST/$NAME/manifests/
   scp ./manifests/stop.pp    root@$1:$PUPPET_DST/$NAME/manifests/
   #scp ./files/...              root@$1:$PUPPET_DST/$NAME/files/
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
   scp $TYPE_SRC/appscale.rb                     root@$1:$TYPE_DST/appscale.rb
   scp $PROVIDER_SRC/$NAME/appscalep.rb          root@$1:$PROVIDER_DST/appscalep.rb
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