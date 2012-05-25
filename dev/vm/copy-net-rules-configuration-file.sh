# Description:
#   Copies net rules configuration file from host to remote host on <IP> address.
#
# Synopsis:
#   copy-net-rules-configuration-file.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: copy-net-rules-configuration-file.sh 192.168.1.100
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -eq 0 ]
then
  echo "You must supply a valid IP:"
  echo "  $0 <IP> "
  exit 1
fi

# Copy files
echo "IP received: $1"

DESTINATION_PATH="root@$1:/root/."

# Copy files
scp ./configure-net-rules.sh     $DESTINATION_PATH
