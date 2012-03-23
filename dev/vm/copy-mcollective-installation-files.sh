# Description:
#   Copies mcollective installation files from host to remote host on <IP> address.
#
# Synopsis:
#   copy-mcollective-installation-files.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: copy-puppet-installation-files.sh 192.168.1.100 
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

MCOLLECTIVE_COMMON="mcollective-common_1.2.1-1_all.deb"
MCOLLECTIVE="mcollective_1.2.1-1_all.deb"
MCOLLECTIVE_CLIENT="mcollective-client_1.2.1-1_all.deb"


DESTINATION_PATH="root@$1:/root/."


scp ../mcollective-installation/$MCOLLECTIVE_COMMON            $DESTINATION_PATH
scp ../mcollective-installation/$MCOLLECTIVE                   $DESTINATION_PATH
scp ../mcollective-installation/$MCOLLECTIVE_CLIENT            $DESTINATION_PATH
scp ../mcollective-installation/mcollective-installation.sh    $DESTINATION_PATH
