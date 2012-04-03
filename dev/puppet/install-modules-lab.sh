# Description:
#   Installs puppet modules
#
# Synopsis:
#   install-lab.sh <IP> <modules>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Modules: Modules to install
#     - all:   all the modules
#     - cloud: cloud module
#     - app:   AppScale module
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#   _$: install-lab.sh 155.210.155.170 cloud
#   _$: install-lab.sh 155.210.155.170 app
#
#
# Author:
#   David Ceresuela

if [ $# -ne 2 ]
then
   echo "Use: $0 <IP address> <modules>"
   echo "Examples
$0 155.210.155.170 all
$0 155.210.155.170 cloud   # For cloud module
$0 155.210.155.170 app     # For appscale module
"
   exit 1
fi 

# Copy cloud module
if [ $2 = "cloud" -o $2 = "all" ]
then
   cd ./cloud-module
   ./install-lab.sh $1 all
   cd ..
fi

# Copy AppScale module
if [ $2 = "app" -o $2 = "all" ]
then
   cd ./appscale-module
   ./install-lab.sh $1 all
   cd ..
fi
