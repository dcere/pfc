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
  if [ $1 = "localhost" ]
  then
    echo "Copying faces to localhost..."
    sudo cp ./face/*.rb $PUPPET_PATH/face/.
    echo "Copying applications to localhost..."
    sudo cp ./application/*.rb $PUPPET_PATH/application/.
    echo "Finished"
  else
    echo "Copying faces to $1..."
    scp ./face/*.rb root@$1:$PUPPET_PATH/face/.
    echo "Copying applications to $1..."
    scp ./application/*.rb root@$1:$PUPPET_PATH/application/.
    echo "Finished"
  fi
fi

if [ $# -eq 2 ]
then
  if [ $1 = "localhost" ]
  then
    echo "Copying face $2 to localhost..."
    sudo cp ./face/*.rb $PUPPET_PATH/face/.
    echo "Copying applications to localhost..."
    sudo cp ./application/*.rb $PUPPET_PATH/application/.
    echo "Finished"
  else
    echo "Copying face $2 to $1..."
    scp ./face/$2.rb root@$1:$PUPPET_PATH/face/.
    echo "Copying application $2 to $1..."
    scp ./application/$2.rb root@$1:$PUPPET_PATH/application/.
    echo "Finished"
  fi
fi
