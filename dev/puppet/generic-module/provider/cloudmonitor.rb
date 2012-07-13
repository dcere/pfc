# Generic monitor functions for a distributed infrastructure
module CloudMonitor

   PING = "ping -q -c 1 -w 4"

   # Checks if the <vm> machine is alive.
   def self.ping(vm)

      result = `#{PING} #{vm}`
      if $?.exitstatus == 0
         puts "[CloudMonitor] #{vm} is up"
         return true
      else
         puts "[CloudMonitor] #{vm} is down"
         return false
      end
      
   end


   # Checks if MCollective is installed in <vm>.
   def self.mcollective_installed(user, vm)
      
      installed = true
      
      # Client configuration file
      client_file = "/etc/mcollective/client.cfg"
      command = "cat #{client_file} > /dev/null 2> /dev/null"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "[CloudMonitor] #{client_file} does not exist on #{user}@#{vm}"
         installed = false
      end

      # Server configuration file
      server_file = "/etc/mcollective/server.cfg"
      command = "cat #{server_file} > /dev/null 2> /dev/null"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "[CloudMonitor] #{server_file} does not exist on #{user}@#{vm}"
         installed = false
      end
      
      return installed
      
   end


   # Checks if MCollective is running in <vm>.
   def self.mcollective_running(user, vm)
      
      command = "ps aux | grep -v grep | grep mcollective"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "MCollective is not running on #{vm}"
         command = "/usr/bin/service mcollective start"
         out, success = CloudSSH.execute_remote(command, user, vm)
         unless success
            puts "[CloudMonitor] Impossible to start mcollective on #{user}@#{vm}"
            return false
         else
            puts "[CloudMonitor] MCollective is running now on #{vm}"
            return true
         end
      else
         puts "[CloudMonitor] MCollective is running on #{vm}"
         return true
      end
      
   end
   
end
