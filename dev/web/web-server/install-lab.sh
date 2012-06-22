# Description:
#   Installs the web server files
#
# Synopsis:
#   install-lab.sh <IP>
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
WEB_DST="/root/cloud/web/server"

# Create directories
$SSH mkdir -p $WEB_DST/views     # It will also make /root/cloud/web/server

# Copy files
scp -r ./            root@$1:$WEB_DST/
scp ./ruby-web3      root@$1:/etc/init.d/
