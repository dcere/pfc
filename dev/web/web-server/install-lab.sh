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
$SSH mkdir -p $WEB_DST/views     # It will also make /root/cloud/web/web

# Copy files
scp ./web.rb               root@$1:$WEB_DST/
scp ./web2.rb              root@$1:$WEB_DST/
scp ./web3.rb              root@$1:$WEB_DST/
scp ./start-ruby-web3      root@$1:$WEB_DST/
scp ./views/index.erb      root@$1:$WEB_DST/views/
