# Description:
#   Installs the cloud puppet module
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
#     - app:   AppScale local manifests
#     - tls:   AppScale tools
#     - web:   Web local manifests and monitor files
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

NAME="cloud"
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
   scp $TYPE_SRC/cloud.rb        root@$1:$TYPE_DST/cloud.rb

   # cloudp.rb, cloud_helper.rb, appscale_yaml.rb, web_yaml.rb,
   # mcollective_files.rb, mcollective_leader.rb, mcollective_cron.rb,
   # mac.rb, vm.rb, ssh_copy_id.sh
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

# Copy AppScale local manifests
if [ $2 = "app" -o $2 = "all" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/files/appscale-manifests
   scp ./files/appscale-manifests/basic.pp \
      root@$1:$PUPPET_DST/$NAME/files/appscale-manifests/basic.pp
fi


# Copy web local manifests and monitor files
if [ $2 = "web" -o $2 = "all" ]
then
   $SSH mkdir -p $PUPPET_DST/$NAME/files/web-manifests
   scp ./files/web-manifests/balancer.pp \
      root@$1:$PUPPET_DST/$NAME/files/web-manifests/balancer.pp
   scp ./files/web-manifests/server.pp \
      root@$1:$PUPPET_DST/$NAME/files/web-manifests/server.pp
   scp ./files/web-manifests/database.pp \
      root@$1:$PUPPET_DST/$NAME/files/web-manifests/database.pp

   $SSH mkdir -p $PUPPET_DST/$NAME/files/web-god
   scp ./files/web-god/server.god \
      root@$1:$PUPPET_DST/$NAME/files/web-god/server.god
   scp ./files/web-god/database.god \
      root@$1:$PUPPET_DST/$NAME/files/web-god/database.god
fi

# Copy jobs local manifests
# ...
