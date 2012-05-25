# Description:
#   Creates a script to delete /etc/udev/rules.d/70-persistent-net.rules file
#   on startup time.
#
# Synopsis:
#   configure-net-rules.sh
#
#
# Examples:
#   _$: configure-net-rules.sh
#
#
# Author:
#   David Ceresuela

cd /etc/init.d
echo "rm /etc/udev/rules.d/70-persistent-net.rules" > cloud-70-net-rules
chmod +x cloud-70-net-rules
update-rc.d cloud-70-net-rules defaults
