# Description:
#   Configures the ssh keys
#
# Synopsis:
#   ssh-configuration.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: ssh-configuration.sh 155.210.155.170
#
#
# Author:
#   David Ceresuela

if [ $# -ne 1 ]
then
   echo "Use: $0 <IP address>"
   echo "Example: $0 155.210.155.170"
   exit 1
fi 

echo "ssh-add to add key..."
ssh-add /home/dceresuela/.ssh/id_rsa.pub
echo "Creating .ssh directory in $1..."
ssh root@$1 'mkdir -p .ssh'
echo "Copying public key to $1..."
cat /home/dceresuela/.ssh/id_rsa.pub | ssh root@$1 'cat >> .ssh/authorized_keys'
