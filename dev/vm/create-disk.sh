# Description:
#   Creates a disk image
#
# Synopsis:
#   create-disk.sh <disk-name> <disk-size> [<format> <path>]
#
# Arguments:
#   - Disk name: The name the disk image will have.
#   - Disk size: The maximum size of the disk.
#   - Format [optional]: The image format: qcow2, raw, etc. Defaults to raw.
#   - Path [optional]: The path where the disk will be created. Defaults to ./
#
# Examples:
#   _$: create-disk.sh disk-2G 2G
#   _$: create-disk.sh disk-2G 2M qcow2
#
#
# Author:
#   David Ceresuela

if [ $# -lt 2 ]
then

echo "Use: $0 <disk-name> <disk-size> [<format> <path>]

Examples:
$0 disk-2G 2G        Creates a disk-2G of 2GB in ./ and raw format
$0 disk-2G 2M qcow2  Creates a disk-2G of 2MB in ./ and qcow2 format

Runs qemu-img create in background, so <disk-size> and <format> parameters
must be like the qemu-img ones
Type \"man qemu-img\" for more information"

  exit 1
fi

if [ $# -eq 2 ]
then
  qemu-img create $1 $2
  chmod 0777 $1 # To avoid home vs lab problems give permissions to everybody
fi

if [ $# -eq 3 ]
then
  qemu-img create -f $3 $1 $2
  chmod 0777 $1
fi

if [ $# -eq 4 ]
then
  qemu-img create -f $3 $4/$1 $2
  chmod 0777 $4/$1
fi
