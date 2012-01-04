# Description:
#   Copies appscale installation files from host to remote host on <IP> address.
#
# Synopsis:
#   copy-appscale-installation-files.sh <IP> [<appscale path> <appscale-tools path>]
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Appscale path [optional]: The path where the appscale folder is.
#       Defaults to current directory ./
#   - Appscale-tools path [optional] The path where the appscale-tools folder is.
#       Defaults to current directory ./
#
# Examples:
#   _$: copy-appscale-installation-files.sh 192.168.1.100 
#   _$: copy-appscale-installation-files.sh 192.168.1.100 myface
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -eq 0 ]
then
  echo "You must supply a valid IP:"
  echo "  $0 <IP> [<appscale path> <appscale-tools path>]"
  exit 1
fi

# Copy files
if [ $# -eq 1 ]
then
  APPSCALE_PATH="./"
  APPSCALE_TOOLS_PATH="./"
fi

if [ $# -eq 2 ]
then
  echo "You must supply a valid IP and both or neither paths:"
  echo "  $0 <IP> [<appscale path> <appscale-tools path>]"
  exit 1
fi

if [ $# -eq 3 ]
then
  APPSCALE_PATH=$2
  APPSCALE_TOOLS_PATH=$3
fi

APPSCALE=appscale-1.5.1
APPSCALE_TOOLS=appscale-tools

DESTINATION_PATH="root@$1:/root/."

scp -r $APPSCALE_PATH/$APPSCALE                $DESTINATION_PATH
scp -r $APPSCALE_TOOLS_PATH/$APPSCALE_TOOLS    $DESTINATION_PATH
