# Description:
#   Installs rubygems
#
# Synopsis:
#   rubygems-installation.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: ./rubygems-installation.sh
#
#
# Author:
#   David Ceresuela

RUBYGEMS="rubygems-1.8.10"


tar xf "$RUBYGEMS.tgz"
rm "$RUBYGEMS.tgz"
cd ./$RUBYGEMS
ruby setup.rb
cd ../
