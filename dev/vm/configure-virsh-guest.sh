# Description:
#   Creates a virsh XML description file
#
# Synopsis:
#   configure-virsh-guest.sh <name> <img path> <mac address>
#
# Arguments:
#   - Name: The name the virsh guest will have.
#   - Img path: The path where the disk is stored.
#   - MAC address: The mac address.
#
# Examples:
#   _$: configure-virsh-guest.sh My-virtual-machine /tmp/disk.img 52:54:de:ad:be:ef"
#
#
# Author:
#   David Ceresuela

ruby ./configure-virsh-guest.rb $1 $2 $3
