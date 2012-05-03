# Description:
#   Copies ruby and rubygems installation files from host to remote host on <IP> address.
#
# Synopsis:
#   copy-ruby-installation-files.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: copy-ruby-installation-files.sh 192.168.1.100 
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

RUBY_STABLE="ruby-1.9.3-p0.tar.gz"
RUBYGEMS="rubygems-1.8.10.tgz"


DESTINATION_PATH="root@$1:/root/."

# Copy files
scp ../ruby-installation/$RUBY_STABLE                 $DESTINATION_PATH
scp ../ruby-installation/$RUBYGEMS                    $DESTINATION_PATH
scp ../ruby-installation/rubygems-installation.sh     $DESTINATION_PATH
