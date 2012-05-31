# Description:
#   Installs torque
#
# Synopsis:
#   torque-installation.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: ./torque-installation.sh
#
#
# Author:
#   David Ceresuela

TORQUE_STABLE="torque-4.0.2"


tar xf "$TORQUE_STABLE.tar.gz"
rm "$TORQUE_STABLE.tar.gz"
cd ./$TORQUE_STABLE
./configure
make
make install

