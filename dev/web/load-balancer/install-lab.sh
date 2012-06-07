# Description:
#   Installs the load balancer files
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

SSH="ssh root@$1"
LB_DST="/etc/nginx/"

# Copy configuration file
scp ./nginx.conf     root@$1:$LB_DST/
