# Description:
#   Installs mcollective
#
# Synopsis:
#   mcollective-installation.sh <mode>
#
# Arguments:
#   - Mode: client(manager) or server(managed)
#
# Examples:
#   _$: ./mcollective-installation.sh client
#   _$: ./mcollective-installation.sh server
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -ne 1 ]
then
   echo "Use: $0 <mode>"
   echo "Examples
$0 client
$0 server
"
   exit 1
fi 

MCOLL_VERSION="1.2.1-1"

# Install rubygems
sudo apt-get install rubygems

# Install client
if [ $1 = "client" ]
then
   sudo dpkg -i mcollective-common_${MCOLL_VERSION}_all.deb
   sudo dpkg -i mcollective-client_${MCOLL_VERSION}_all.deb
fi

# Install server
if [ $1 = "server" ]
then
   sudo dpkg -i mcollective-common_${MCOLL_VERSION}_all.deb
   sudo dpkg -i mcollective_${MCOLL_VERSION}_all.deb
fi

# Install linstompruby library
sudo aptitude install libstomp-ruby
