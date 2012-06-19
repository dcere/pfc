#!/usr/bin/env expect

# Description:
#   Interacts with the appscale-run-instances tool
#
# Synopsis:
#   appscale-run-instances.tcl <file> <e-mail> <password>
#
# Arguments:
#   - File: AppScale YAML configuration file.
#   - e-mail: AppScale administration e-mail.
#   - Password: AppScale administration password.
#
# Examples:
#   _$: appscale-run-instances.tcl ips.yaml user@mail.com appscale
#
#
# Author:
#   David Ceresuela


# Procedure to interact with appscale-run-instances command
# Parameter : user
# Parameter : password 
proc runinstances { user password } {
  expect {
    # Send e-mail address
    -re "e-mail address:" { exp_send "$user\r"
                            exp_continue }

    # Send password
    -re "new password:" { exp_send "$password\r"
                          exp_continue }
    
    # Send password again to verify
    -re "again to verify:" { exp_send "$password\r"
                             exp_continue }
    
            
    # Tell expect stay in this 'expect' block and for each character that
    # appscale-run-instances prints while doing the copy
    # Reset the timeout counter back to 0
    -re .                { exp_continue  }
    timeout              { return 1      }
    
    # Returning 0 as appscale-run-instances was successful
    eof                  { return 0      }
  }
}

#Parsing command-line arguments
set yaml     [lrange $argv 0 0]
set user     [lrange $argv 1 1]
set password [lrange $argv 2 2]

#Setting timeout to an arbitrary value of 120 that works well for appscale-run-instances
set timeout 120

# Execute appscale-run-instances command
eval spawn /usr/local/appscale-tools/bin/appscale-run-instances --ips $yaml

#Get the result of appscale-run-instances
set runinstances_result [runinstances $user $password]

# If appscale-run-instances was successful
if { $runinstances_result == 0 } {
  #Exit with zero status
  exit 0
}

# Error attempting appscale-run-instances, so exit with non-zero status
exit 1
