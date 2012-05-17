# Description:
#   Installs the mcollective agents
#
# Synopsis:
#   install-lab.sh <IP> <files>
#
# Arguments:
#   - IP address: IP address of remote host.
#   - Files: Files to install
#     - all:    all agents
#     - files:  files agent
#     - leader: leader election agent
#     - cronos: cron agent
#
# Examples:
#   _$: install-lab.sh 155.210.155.170 all
#   _$: install-lab.sh 155.210.155.170 files
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -ne 2 ]
then
   echo "Use: $0 <IP address> <set of agents>"
   echo "Examples
$0 155.210.155.170 all
$0 155.210.155.170 files
"
   exit 1
fi 

MCOLL_DST="/usr/share/mcollective/plugins/mcollective/agent"


# Copy agents
if [ $2 = "files" -o $2 = "all" ]
then
   scp ./rpc/files.ddl     root@$1:$MCOLL_DST/
   scp ./rpc/files.rb      root@$1:$MCOLL_DST/
fi

if [ $2 = "leader" -o $2 = "all" ]
then
   scp ./rpc/leader.ddl     root@$1:$MCOLL_DST/
   scp ./rpc/leader.rb      root@$1:$MCOLL_DST/
fi

if [ $2 = "cronos" -o $2 = "all" ]
then
   scp ./rpc/cronos.ddl     root@$1:$MCOLL_DST/
   scp ./rpc/cronos.rb      root@$1:$MCOLL_DST/
fi
