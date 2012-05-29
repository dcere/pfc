# Starts a web cloud.
def web_cloud_start(web_roles)
   
   # TODO   ssh to itself? Does it work if keys are distributed? Should it make
   #        a clear distinction between ssh to itself or others?

   balancers = web_roles[:balancer]
   servers   = web_roles[:server]
   databases = web_roles[:database]

   # Start services
   
   # Start load balancers => Start nginx
   puts "Starting nginx on load balancers"
   command = "/etc/init.d/nginx start > /dev/null 2> /dev/null"
   balancers.each do |vm|
      if vm == MY_IP
         result = `#{command}`
         unless $?.exitstatus == 0
            err "Impossible to start balancer in #{vm}"
         end
      else
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            err "Impossible to start balancer in #{vm}"
         end
      end
   end
   
   # Start web servers => Start sinatra application
   puts "Starting ruby web3 on web servers"
   command = "/bin/bash /root/web/start-ruby-web3"
   servers.each do |vm|
      if vm == MY_IP
         result = `#{command}`
         unless $?.exitstatus == 0
            err "Impossible to start server in #{vm}"
         end
      else
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            err "Impossible to start server in #{vm}"
         end
      end
   end
   
   # Database servers start at boot time, but check whether they have started
   # and if they have not, start them
   puts "Starting mysql on database servers"
   check_command = "ps aux | grep -v grep | grep mysql"
   command = "/usr/bin/service mysql start"
   databases.each do |vm|
      if vm == MY_IP
         result = `#{check_command}`
         unless $?.exitstatus == 0
            result = `#{command}`
            unless $?.exitstatus == 0
               err "Impossible to start database in #{vm}"
            end
         end
      else
         out, success = CloudSSH.execute_remote(check_command, vm)
         unless success
            out, success = CloudSSH.execute_remote(command, vm)
            unless success
               err "Impossible to start database in #{vm}"
            end
         end
      end
   end
   
   
   # Start monitoring
   
   # Load balancers
   balancers.each do |vm|
      start_monitor_balancer(vm)
   end
   
   # Web servers
   servers.each do |vm|
      start_monitor_server(vm)
   end
   
   # Database servers
   databases.each do |vm|
      start_monitor_database(vm)
   end
   
end


# Monitors a virtual machine belonging to a web cloud.
def web_monitor(vm, role)

   if role == :balancer
      puts "[Web monitor] Monitoring load balancer"
      
      # Run puppet
      unless start_monitor_balancer(vm)
         puts "[Web monitor] Impossible to monitor load balancer on #{vm}"
      end
      puts "[Web monitor] Monitored load balancer"

   elsif role == :server
      puts "[Web monitor] Monitoring web server"
      
      # Check god is running
      check_command = "ps aux | grep -v grep | grep god | grep server.god"
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         err "God is not running in #{vm}"
         
         # Try to start monitoring again
         puts "[Web monitor] Starting monitoring server on #{vm}"
         if start_monitor_server(vm)
            puts "[Web monitor] Successfully started to monitor server on #{vm}"
         else
            puts "[Web monitor] Impossible to monitor server on #{vm}"
         end
      end
      puts "[Web monitor] Monitored web server"

   elsif role == :database
      puts "[Web monitor] Monitoring database"
      
      # Check god is running
      check_command = "ps aux | grep -v grep | grep god | grep database.god"
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         err "God is not running in #{vm}"
         
         # Try to start monitoring again
         puts "[Web monitor] Starting monitoring database on #{vm}"
         if start_monitor_database(vm)
            puts "[Web monitor] Successfully started to monitor database on #{vm}"
         else
            puts "[Web monitor] Impossible to monitor database on #{vm}"
         end
      end
      puts "[Web monitor] Monitored database"

   else
      puts "[Web monitor] Unknown role: #{role}"
   end
   
end


################################################################################
# Auxiliar functions
################################################################################
def start_monitor_balancer(vm)

   # Copy the puppet manifest
   path = "/etc/puppet/modules/cloud/files/web-manifests/balancer.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "Impossible to copy balancer manifest to #{vm}"
      return false
   end

   # Monitor load balancer with puppet
   # While god monitoring will be done in a loop this will only be done if
   # explicitly invoked, so we must call 'puppet apply' every time.
   command = "puppet apply /tmp/balancer.pp"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to run puppet in #{vm}"
      return false
   end
   return true
   
end


def start_monitor_server(vm)

   # Copy the puppet manifest
   path = "/etc/puppet/modules/cloud/files/web-manifests/server.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "Impossible to copy server manifest to #{vm}"
      return false
   end
   
   # Monitor web servers with puppet: installation files and required gems
   command = "puppet apply /tmp/server.pp"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to run puppet in #{vm}"
      return false
   end
   
   # Monitor web servers with god: web server is up and running
   path = "/etc/puppet/modules/cloud/files/web-god/server.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "Impossible to copy #{path} to #{vm}"
      return false
   end
   command = "god -c /etc/god/server.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to run god in #{vm}"
      return false
   end
   return true

end


def start_monitor_database(vm)

   # Monitor database with god due to puppet vs ubuntu mysql bug
   # http://projects.puppetlabs.com/issues/12773
   # Therefore there is no puppet monitoring, only god
   path = "/etc/puppet/modules/cloud/files/web-god/database.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "Impossible to copy #{path} to #{vm}"
      return false
   end
   command = "god -c /etc/god/database.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to run god in #{vm}"
      return false
   end
   return true

end
