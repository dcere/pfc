# Description:
#   Copies torque installation files from host to remote host on <IP> address.
#
# Synopsis:
#   copy-torque-installation-files.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: copy-torque-installation-files.sh 192.168.1.100
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

TORQUE_STABLE="torque-4.0.2.tar.gz"
TORQUE_INSTALL="torque-installation.sh"

DESTINATION_PATH="root@$1:/root/."

# Copy files
scp ../torque-installation/$TORQUE_STABLE       $DESTINATION_PATH
scp ../torque-installation/$TORQUE_INSTALL      $DESTINATION_PATH
