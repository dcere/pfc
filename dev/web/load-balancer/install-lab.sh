# Description:
#   Installs the load balancer files
#
# Synopsis:
#   install-lab.sh <IP> <files>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:  all the files
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#
#
# Author:
#   David Ceresuela

if [ $# -ne 2 ]
then
   echo "Use: $0 <IP address> <set of files>"
   echo "Examples
$0 155.210.155.170 all
"
   exit 1
fi 

SSH="ssh root@$1"
LB_DST="/etc/nginx/"

# Create directories
$SSH mkdir -p $WEB_DST/views

# Copy manifests
if [ $2 = "all" ]
then
   scp ./nginx.conf     root@$1:$LB_DST/
fi
