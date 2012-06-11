#!/usr/bin/env expect

# Description:
#   Interacts with the appscale-add-keypair tool
#
# Synopsis:
#   appscale-add-keypair.tcl <password>
#
# Arguments:
#   - File: AppScale YAML configuration file.
#   - Password: Root password for all machines.
#
# Examples:
#   _$: appscale-add-keypair.tcl ips.yaml my_password_is_abcd
#
#
# Author:
#   David Ceresuela


# Procedure to interact with appscale-add-keypair command
# Parameter : password 
proc addkeypair { password } {
  expect {
    # Send password
    -re "SSH password of root:" { exp_send "$password\r"
                                  exp_continue }
    
    # Tell expect stay in this 'expect' block and for each character that
    # appscale-add-keypair prints while doing the copy
    # Reset the timeout counter back to 0
    -re .                { exp_continue  }
    timeout              { return 1      }
    
    # Returning 0 as appscale-add-keypair was successful
    eof                  { return 0      }
  }
}

#Parsing command-line arguments
set yaml     [lrange $argv 0 0]
set password [lrange $argv 1 1]

#Setting timeout to an arbitrary value of 120 that works well for appscale-add-keypair
set timeout 120

# Execute appscale-add-keypair command
eval spawn /usr/local/appscale-tools/bin/appscale-add-keypair --ips $yaml --auto

#Get the result of appscale-add-keypair
set addkeypair_result [addkeypair $password]

# If appscale-add-keypair was successful
if { $addkeypair_result == 0 } {
  #Exit with zero status
  exit 0
}

# Error attempting appscale-add-keypair, so exit with non-zero status
exit 1
