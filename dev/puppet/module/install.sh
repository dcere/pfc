# Description:
#   Installs the cloud puppet module
#
# Synopsis:
#   install.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: install.sh
#
#
# Author:
#   David Ceresuela

NAME="cloud"

mkdir –p /etc/puppet/modules/$NAME/{files,templates,manifests}
cp ./manifests/init.pp /etc/puppet/modules/$NAME/manifests/init.pp

