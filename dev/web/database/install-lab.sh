# Description:
#   Installs the database files
#
# Synopsis:
#   install-lab.sh <IP> <files>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:  all the files
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#
#
# Author:
#   David Ceresuela

if [ $# -ne 2 ]
then
   echo "Use: $0 <IP address> <set of files>"
   echo "Examples
$0 155.210.155.170 all
"
   exit 1
fi 

SSH="ssh root@$1"
DB_DST="/root/db"

# Create directories
$SSH mkdir -p $DB_DST/

# Copy manifests
if [ $2 = "all" ]
then
   scp ./create-db.sql           root@$1:$DB_DST/
   scp ./create-table.sql        root@$1:$DB_DST/
   scp ./insert-table.sql        root@$1:$DB_DST/
   scp ./select-table.sql        root@$1:$DB_DST/
   scp ./create-user.sql         root@$1:$DB_DST/
   scp ./grant-user-table.sql    root@$1:$DB_DST/
   scp ./set-db.sh               root@$1:$WEB_DST/
   scp ./examples.sh             root@$1:$WEB_DST/
fi
