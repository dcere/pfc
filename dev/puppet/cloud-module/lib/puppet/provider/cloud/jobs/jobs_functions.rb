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
      command = "/usr/local/sbin/pbs_server"
      out, success = CloudSSH.execute_remote(command, head)
      unless success
         err "Impossible to start pbs_server in #{head}"
         return false
      end
   end
   
   # Start compute
   puts "Starting pbs_mom on compute nodes"
   check_command = "ps aux | grep -v grep | grep pbs_mom"
   command = "/usr/local/sbin/pbs_mom"
   compute.each do |vm|
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            err "Impossible to start pbs_mom in #{vm}"
            return false
         end
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
      puts "[Torque monitor] Monitored head"

   elsif role == :compute
      puts "[Torque monitor] Monitoring compute"
      puts "[Torque monitor] Monitored compute"

   else
      puts "[Torque monitor] Unknown role: #{role}"
   end
   
end
