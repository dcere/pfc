# Description:
#   Installs the jobs files needed to start pbs_* as daemons
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

SSH="ssh root@$1"
JOBS_DST="/root/jobs"

# Create directories
$SSH mkdir -p $JOBS_DST

# Copy files
scp ./start-pbs-mom        root@$1:$JOBS_DST/
scp ./start-pbs-server     root@$1:$JOBS_DST/
scp ./start-pbs-sched      root@$1:$JOBS_DST/
