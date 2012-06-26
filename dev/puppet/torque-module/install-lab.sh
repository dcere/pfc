# Description:
#   Installs the torque puppet module
#
# Synopsis:
#   install-lab.sh <user> <IP> <files>
#
# Arguments:
#   - User: User of remote host.
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:   all the files
#     - man:   only manifests
#     - tp:    only type and provider
#     - files: only type and provider files directory
#     - test:  only test files
#     - trq:   Torque local manifests and monitor files
#
# Examples:
#   _$: install-lab.sh root 155.210.155.170 all
#   _$: install-lab.sh root 155.210.155.170 tp
#   _$: install-lab.sh root 155.210.155.170 man
#   _$: install-lab.sh root 155.210.155.170 files
#
#
# Author:
#   David Ceresuela

if [ $# -ne 3 ]
then
   echo "Use: $0 <user> <IP address> <set of files>"
   echo "Examples
$0 root  155.210.155.170 all
$0 david 155.210.155.170 tp
"
   exit 1
fi

NAME="torque"
PUPPET_DST="/etc/puppet/modules"

SSH="ssh $1@$2"

# Create directories
if [ $3 != "trq" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME
   $SSH mkdir -p $PUPPET_DST/$NAME/files/{cron,torque-god,torque-start}
fi

# Copy manifests
if [ $3 = "man" -o $3 = "all" ]
then
   scp ./manifests/*    $1@$2:$PUPPET_DST/$NAME/manifests/
fi

# Copy type and provider
TYPE_SRC="./lib/puppet/type"
TYPE_DST="$PUPPET_DST/$NAME/lib/puppet/type"
PROVIDER_SRC="./lib/puppet/provider"
PROVIDER_DST="$PUPPET_DST/$NAME/lib/puppet/provider/$NAME"

if [ $3 = "tp" -o $3 = "all" ]
then
   scp $TYPE_SRC/torque.rb          $1@$2:$TYPE_DST/torque.rb

   # All provider files
   scp -r $PROVIDER_SRC/$NAME/*     $1@$2:$PROVIDER_DST/
fi

# Copy type and provider files directory
if [ $3 = "files" -o $3 = "all" ]
then
   scp -r ./files/*     $1@$2:$PUPPET_DST/$NAME/files/
fi

# Copy test
if [ $3 = "test" -o $3 = "all" ]
then
   scp ./test.rb     $1@$2:$PUPPET_DST/$NAME
fi

# Copy validation script
if [ $3 = "test" -o $3 = "all" ]
then
   scp ./validate.sh    $1@$2:$PUPPET_DST/$NAME
fi

# Copy Torque monitor files ans start scripts
if [ $1 = "root" ]
then
   TORQUE_DST="/$1/cloud/torque"
else
   TORQUE_DST="/home/$1/cloud/torque"
fi

if [ $3 = "trq" -o $3 = "all" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/files/torque-god
   scp ./files/torque-god/*      $1@$2:$PUPPET_DST/$NAME/files/torque-god/
   
   $SSH mkdir -p $PUPPET_DST/$NAME/files/torque-start
   scp ./files/torque-start/*    $1@$2:$PUPPET_DST/$NAME/files/torque-start/
   
   $SSH mkdir -p $TORQUE_DST
   scp ./files/torque-start/*    $1@$2:$TORQUE_DST/
fi
