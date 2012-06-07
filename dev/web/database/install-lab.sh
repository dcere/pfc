# Description:
#   Installs the database files
#
# Synopsis:
#   install-lab.sh <IP>
#
# Arguments:
#   - IP address: IP address of remote host.
#
# Examples:
#   _$: install-lab.sh 155.210.155.170
#
#
# Author:
#   David Ceresuela

if [ $# -ne 1 ]
then
   echo "Use: $0 <IP address>"
   echo "Examples
$0 155.210.155.170
"
   exit 1
fi 

SSH="ssh root@$1"
DB_DST="/root/cloud/web/db"

# Create directories
$SSH mkdir -p $DB_DST/

# Copy database files: SQL files and scripts
scp ./*     root@$1:$DB_DST/
