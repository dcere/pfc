# Description:
#   Installs the torque puppet module
#
# Synopsis:
#   install-lab.sh <IP> <files>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:   all the files
#     - man:   only manifests
#     - tp:    only type and provider
#     - files: only type and provider files directory
#     - test:  only test files
#     - jobs:  Jobs local manifests and monitor files
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#   _$: install-lab.sh 155.210.155.170 tp
#   _$: install-lab.sh 155.210.155.170 man
#   _$: install-lab.sh 155.210.155.170 files
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

NAME="torque"
PUPPET_DST="/etc/puppet/modules"

SSH="ssh root@$1"

# Create directories
if [ $2 != "app" -o $2 != "web" -o $2 != "jobs" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/{files,templates,manifests}
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/type
   $SSH mkdir -p $PUPPET_DST/$NAME/lib/puppet/provider/$NAME
   $SSH mkdir -p $PUPPET_DST/$NAME/files/{appscale-manifests,appscale-tools,cron,web-manifests,web-god}
fi

# Copy manifests
if [ $2 = "man" -o $2 = "all" ]
then
   scp ./manifests/*    root@$1:$PUPPET_DST/$NAME/manifests/
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
   scp $TYPE_SRC/torque.rb        root@$1:$TYPE_DST/torque.rb

   # All provider files
   scp -r $PROVIDER_SRC/$NAME/*     root@$1:$PROVIDER_DST/
fi

# Copy type and provider files directory
if [ $2 = "files" -o $2 = "all" ]
then
   scp -r ./files/*     root@$1:$PUPPET_DST/$NAME/files/
fi

# Copy test
if [ $2 = "test" -o $2 = "all" ]
then
   scp ./test.rb root@$1:$PUPPET_DST/$NAME
fi

# Copy validation script
if [ $2 = "test" -o $2 = "all" ]
then
   scp ./validate.sh    root@$1:$PUPPET_DST/$NAME

fi


# Copy jobs monitor files ans start scripts
JOBS_DST="/root/cloud/jobs"
if [ $2 = "jobs" -o $2 = "all" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/files/jobs-god
   scp ./files/jobs-god/*     root@$1:$PUPPET_DST/$NAME/files/jobs-god/
   
   $SSH mkdir -p $PUPPET_DST/$NAME/files/jobs-start
   scp ./files/jobs-start/*     root@$1:$PUPPET_DST/$NAME/files/jobs-start/
   
   $SSH mkdir -p $JOBS_DST
   scp ./files/jobs-start/*     root@$1:$JOBS_DST/
fi
