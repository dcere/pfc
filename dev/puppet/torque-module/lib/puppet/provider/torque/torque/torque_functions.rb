# Starts a torque cloud.
def torque_cloud_start(torque_roles)

   head    = torque_roles[:head]
   compute = torque_roles[:compute]

   # Start services
   
   # Start head node
   start_head(head)
   
   # Start compute nodes
   compute.each do |vm|
      start_compute(head, vm)
   end
   
   
   # Start monitoring
   torque_monitor(head, :head)
   compute.each do |vm|
      torque_monitor(vm, :compute)
   end
   
   return true
   
end


################################################################################
# Start node functions
################################################################################

# Starts a head node.
def start_head(head)
   
   puts "Starting trqauthd on head node"
   check_command = "ps aux | grep -v grep | grep trqauthd"
   out, success = CloudSSH.execute_remote(check_command, head)
   unless success
      command = "/etc/init.d/trqauthd start > /dev/null 2> /dev/null"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to start trqauthd in #{head}"
         return false
      end
   end
   
   puts "Starting pbs_server on head node"
   check_command = "ps aux | grep -v grep | grep pbs_server"
   out, success = CloudSSH.execute_remote(check_command, head)
   unless success
      command = "/bin/bash /root/cloud/torque/start-pbs-server"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to start pbs_server in #{head}"
         return false
      end
   end
   
   puts "Starting pbs_sched on head node"
   check_command = "ps aux | grep -v grep | grep pbs_sched"
   out, success = CloudSSH.execute_remote(check_command, head)
   unless success
      command = "/bin/bash /root/cloud/torque/start-pbs-sched"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to start pbs_sched in #{head}"
         return false
      end
   end

end


# Starts a compute node.
def start_compute(head, compute)

   puts "Starting pbs_mom on compute nodes"
   check_command = "ps aux | grep -v grep | grep pbs_mom"
   command = "/bin/bash /root/cloud/torque/start-pbs-mom"
   out, success = CloudSSH.execute_remote(check_command, compute)
   unless success
      out, success = CloudSSH.execute_remote(command, compute)
      unless success
         err "Impossible to start pbs_mom in #{compute}"
         return false
      end
      
      # Add the node to the compute node list on head
      add_compute_node(compute, head)
   end

end


################################################################################
# Monitor node functions
################################################################################

# Monitors a virtual machine belonging to a torque cloud.
def torque_monitor(vm, role)

   if role == :head
      puts "[Torque monitor] Monitoring head"
      monitor_head(vm)
      puts "[Torque monitor] Monitored head"

   elsif role == :compute
      puts "[Torque monitor] Monitoring compute"
      monitor_compute(vm)
      puts "[Torque monitor] Monitored compute"

   else
      puts "[Torque monitor] Unknown role: #{role}"
   end
   
end


# Monitors a head node.
def monitor_head(vm)

   check_command1 = "ps aux | grep -v grep | grep trqauthd"
   check_command2 = "ps aux | grep -v grep | grep god | grep pbs-server.god"
   check_command3 = "ps aux | grep -v grep | grep god | grep pbs-sched.god"
   
   out1, success1 = CloudSSH.execute_remote(check_command1, vm)
   out2, success2 = CloudSSH.execute_remote(check_command2, vm)
   out3, success3 = CloudSSH.execute_remote(check_command3, vm)
   unless success1 && success2 && success3
      puts "[Torque monitor] God or trqauthd are not running in #{vm}"
      
      # Try to start monitoring again
      puts "[Torque monitor] Starting monitoring head on #{vm}"
      if start_monitor_head(vm)
         puts "[Torque monitor] Successfully started to monitor head on #{vm}"
      else
         err "[Torque monitor] Impossible to monitor head on #{vm}"
      end
   end
   
end


# Monitors a compute node.
def monitor_compute(vm)

   # Obtain head node's IP
   vm_ips, vm_ip_roles = torque_yaml_ips(resource[:ip_file])
   head = vm_ip_roles[:head]

   # Check if the node is in the list of compute nodes
   command = "qmgr -c \"list node @localhost\""      # Get a list of all nodes
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "[Torque monitor] Impossible to obtain node list from #{head}"
   end

   command = "hostname"
   out2, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to obtain hostname for #{vm}"
   end

   # Add the node to the list of compute nodes
   hostname = out2.chomp()
   if out.include? "Node #{hostname}"
      puts "[Torque monitor] #{hostname} (#{vm}) already in head's list node"
   else
      puts "[Torque monitor] Adding #{hostname} to the list of compute nodes"
      add_compute_node(vm, head)
   end

   # Start monitoring
   check_command = "ps aux | grep -v grep | grep god | grep pbs-mom.god"
   out, success = CloudSSH.execute_remote(check_command, vm)
   unless success
      puts "[Torque monitor] God is not running in #{vm}"
      
      # Try to start monitoring again
      puts "[Torque monitor] Starting monitoring compute on #{vm}"
      if start_monitor_compute(vm)
         puts "[Torque monitor] Successfully started to monitor compute on #{vm}"
      else
         err "[Torque monitor] Impossible to monitor compute on #{vm}"
      end
   end
   
end


################################################################################
# Stop functions
################################################################################

# Stops a torque cloud.
def torque_cloud_stop(torque_roles)

   head    = torque_roles[:head]
   compute = torque_roles[:compute]
   
   # Stop compute nodes
   compute.each do |vm|
      stop_compute(vm)
   end
   
   # Stop head node
   stop_head(head)
   
end


# Stops a head node.
def stop_head(head)
   
   puts "Stopping pbs_sched on head node"
   command = "pkill -f pbs-sched"      # We are looking for pbs-sched.god
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      command = "pkill pbs_sched"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to stop pbs_sched in #{head}"
         return false
      end
   end
   
   puts "Stopping pbs_server on head node"
   command = "pkill -f pbs-server"     # We are looking for pbs-server.god
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      command = "pkill pbs_server"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to stop pbs_server in #{head}"
         return false
      end
   end
   
   puts "Stopping trqauthd on head node"
   command = "/etc/init.d/trqauthd stop"     # Do not kill it, stop it
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "Impossible to stop trqauthd in #{head}"
      return false
   end

end


# Stops a compute node.
def stop_compute(compute)

   puts "Stopping pbs_mom on compute nodes"
   command = "pkill -f pbs-mom.god"
   out, success = CloudSSH.execute_remote(command, compute)
   unless success
      command = "pkill -f pbs_mom"
      out, success = CloudSSH.execute_remote(command, compute)
      unless success
         err "Impossible to stop pbs_mom in #{compute}"
         return false
      end
      
      # Add the node to the compute node list on head
      del_compute_node(compute, head)
   end

end


################################################################################
# Auxiliar start and stop node functions
################################################################################

# Adds a compute node to the list in the head node.
def add_compute_node(vm, head)

   command = "hostname"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to obtain hostname for #{vm}"
      return false
   end
   hostname = out.chomp()
   command = "qmgr -c \"create node #{hostname}\""
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "Impossible to add #{hostname} as a compute node in #{head}"
      return false
   end
   command = "pbsnodes -c #{hostname}"
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "Impossible to clear offline from #{hostname} in #{head}"
      return false
   end
   
end


# Deletes a compute node from the list in the head node.
def del_compute_node(vm, head)

   command = "hostname"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to obtain hostname for #{vm}"
      return false
   end
   hostname = out
   command = "qmgr -c \"delete node #{hostname}\""
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "Impossible to delete #{hostname} as a compute node in #{head}"
      return false
   end
   
end


################################################################################
# Auxiliar monitor node functions
################################################################################

# Starts monitoring on head node.
def start_monitor_head(vm)
   
   # The trqauthd script is intelligent enough to be initiated as many times
   # as you want without problem: if it is already started it will not be
   # started again
   command = "/etc/init.d/trqauthd start > /dev/null 2> /dev/null"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run /etc/init.d/trqauthd start at #{vm}"
      return false
   end
   
   # Monitor head node pbs_server and pbs_sched processes with god
   
   # pbs_server is up and running
   path = "/etc/puppet/modules/torque/files/torque-god/pbs-server.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "[Torque monitor] Impossible to copy #{path} to #{vm}"
      return false
   end
   port = 17165
   command = "god -c /etc/god/pbs-server.god -p #{port}"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run god in #{vm}"
      return false
   end
   
   # pbs_sched is up and running
   path = "/etc/puppet/modules/torque/files/torque-god/pbs-sched.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "[Torque monitor] Impossible to copy #{path} to #{vm}"
      return false
   end
   port = 17166
   command = "god -c /etc/god/pbs-sched.god -p #{port}"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run god in #{vm}"
      return false
   end
   
   return true

end


# Starts monitoring on compute node.
def start_monitor_compute(vm)
   
   # Monitor compute node with god: pbs_mom is up and running
   path = "/etc/puppet/modules/torque/files/torque-god/pbs-mom.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "[Torque monitor] Impossible to copy #{path} to #{vm}"
      return false
   end
   command = "god -c /etc/god/pbs-mom.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run god in #{vm}"
      return false
   end
   
   return true

end
