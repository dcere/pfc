# Starts a jobs cloud.
def jobs_cloud_start(jobs_roles)

   head    = jobs_roles[:head]
   compute = jobs_roles[:compute]

   # Start services
   
   # Start head
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
      #command = "/usr/local/sbin/pbs_server"
      command = "/bin/bash /root/jobs/start-pbs-server"
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
      #command = "/usr/local/sbin/pbs_server"
      command = "/bin/bash /root/jobs/start-pbs-sched"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to start pbs_server in #{head}"
         return false
      end
   end
   
   # Start compute
   puts "Starting pbs_mom on compute nodes"
   check_command = "ps aux | grep -v grep | grep pbs_mom"
   #command = "/usr/local/sbin/pbs_mom"
   command = "/bin/bash /root/jobs/start-pbs-mom"
   compute.each do |vm|
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            err "Impossible to start pbs_mom in #{vm}"
            return false
         end
         
         # Add the node to the compute node list on head
         add_compute_node(vm, head)
      end
   end
   
   
   # Start monitoring
   jobs_monitor(head, :head)
   compute.each do |vm|
      jobs_monitor(vm, :compute)
   end
   
   return true
   
end


# Monitors a virtual machine belonging to a jobs cloud.
def jobs_monitor(vm, role)

   if role == :head
      puts "[Torque monitor] Monitoring head"
      start_monitor_head(vm)
      puts "[Torque monitor] Monitored head"

   elsif role == :compute
      puts "[Torque monitor] Monitoring compute"
      
      # Obtain head node's IP
      vm_ips, vm_ip_roles = jobs_yaml_ips(resource[:ip_file])
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
      start_monitor_compute(vm)
      
      puts "[Torque monitor] Monitored compute"

   else
      puts "[Torque monitor] Unknown role: #{role}"
   end
   
end


# Stops a jobs cloud.
def jobs_cloud_stop(jobs_roles)

   head    = jobs_roles[:head]
   compute = jobs_roles[:compute]
   
   compute.each do |vm|
      del_compute_node(vm, head)
   end
   
end


################################################################################
# Auxiliar functions
################################################################################

# Adds a compute node to the list in the head node.
def add_compute_node(vm, head)

   command = "hostname"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to obtain hostname for #{vm}"
      return false
   end
   hostname = out
   command = "qmgr -c \"create node #{hostname}\""
   out, success = CloudSSH.execute_remote(command, head)
   unless success
      err "Impossible to add #{hostname} as a compute node in #{head}"
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
   path = "/etc/puppet/modules/cloud/files/jobs-god/pbs-server.god"
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
   command = "god -c /etc/god/pbs-server.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run god in #{vm}"
      return false
   end
   
   # pbs_sched is up and running
   path = "/etc/puppet/modules/cloud/files/jobs-god/pbs-sched.god"
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
   command = "god -c /etc/god/pbs-sched.god"
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
   path = "/etc/puppet/modules/cloud/files/jobs-god/pbs-server.god"
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
   command = "god -c /etc/god/pbs-server.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Torque monitor] Impossible to run god in #{vm}"
      return false
   end
   
   return true

end
