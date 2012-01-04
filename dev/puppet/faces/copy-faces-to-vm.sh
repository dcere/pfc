# Description:
#   Copies all faces from host to remote host on <IP> address.
#
# Synopsis:
#   copy-faces-to-vm.sh <IP> [<face>]
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Face [optional]: The face to be copied. If not included will copy all the
#       faces found on the face directory and application directory.
#
# Examples:
#   _$: copy-faces-to-vm.sh 192.168.1.100
#   _$: copy-faces-to-vm.sh 192.168.1.100 myface
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -eq 0 ]
then
  echo "You must supply a valid IP:"
  echo "  $0 <IP> [<face>]"
  exit 1
fi

# Copy files
PUPPET_PATH="/usr/local/lib/site_ruby/1.8/puppet"

if [ $# -eq 1 ]
then
  echo "Copying faces..."
  scp ./face/*.rb root@$1:$PUPPET_PATH/face/.

  echo "Copying applications..."
  scp ./application/*.rb root@$1:$PUPPET_PATH/application/.
  
  echo "Finished"
fi

if [ $# -eq 2 ]
then
  echo "Copying face $2..."
  scp ./face/*.rb root@$1:$PUPPET_PATH/face/.

  echo "Copying application $2..."
  scp ./application/*.rb root@$1:$PUPPET_PATH/application/.
  
  echo "Finished"
fi
