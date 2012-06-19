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
   balancers.each do |vm|
      start_balancer(vm)
   end
   
   # Start web servers => Start sinatra application
   puts "Starting ruby web3 on web servers"
   servers.each do |vm|
      start_server(vm)
   end
   
   # Database servers start at boot time, but check whether they have started
   # and if they have not, start them
   puts "Starting mysql on database servers"
   databases.each do |vm|
      start_database(vm)
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
   
   return true
   
end


################################################################################
# Start node functions
################################################################################

# Starts a load balancer.
def start_balancer(vm)
   
   command = "/etc/init.d/nginx start > /dev/null 2> /dev/null"
   if vm == MY_IP
      result = `#{command}`
      unless $?.exitstatus == 0
         err "Impossible to start balancer in #{vm}"
         return false
      end
   else
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         err "Impossible to start balancer in #{vm}"
         return false
      end
   end

end


# Starts a web server.
def start_server(vm)

   command = "/bin/bash /root/cloud/web/server/start-ruby-web3"
   if vm == MY_IP
      result = `#{command}`
      unless $?.exitstatus == 0
         err "Impossible to start server in #{vm}"
         return false
      end
   else
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         err "Impossible to start server in #{vm}"
         return false
      end
   end

end


# Starts a database server.
def start_database(vm)
   
   check_command = "ps aux | grep -v grep | grep mysql"
   command = "/usr/bin/service mysql start"
   if vm == MY_IP
      result = `#{check_command}`
      unless $?.exitstatus == 0
         result = `#{command}`
         unless $?.exitstatus == 0
            err "Impossible to start database in #{vm}"
            return false
         end
      end
   else
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            err "Impossible to start database in #{vm}"
            return false
         end
      end
   end
   
end


################################################################################
# Monitor node functions
################################################################################

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
         puts "[Web monitor] God is not running in #{vm}"
         
         # Try to start monitoring again
         puts "[Web monitor] Starting monitoring server on #{vm}"
         if start_monitor_server(vm)
            puts "[Web monitor] Successfully started to monitor server on #{vm}"
         else
            err "[Web monitor] Impossible to monitor server on #{vm}"
         end
      end
      puts "[Web monitor] Monitored web server"

   elsif role == :database
      puts "[Web monitor] Monitoring database"
      
      # Check god is running
      check_command = "ps aux | grep -v grep | grep god | grep database.god"
      out, success = CloudSSH.execute_remote(check_command, vm)
      unless success
         puts "[Web monitor] God is not running in #{vm}"
         
         # Try to start monitoring again
         puts "[Web monitor] Starting monitoring database on #{vm}"
         if start_monitor_database(vm)
            puts "[Web monitor] Successfully started to monitor database on #{vm}"
         else
            err "[Web monitor] Impossible to monitor database on #{vm}"
         end
      end
      puts "[Web monitor] Monitored database"

   else
      puts "[Web monitor] Unknown role: #{role}"
   end
   
end


# Starts monitoring on load balancer.
def start_monitor_balancer(vm)

   # Copy the puppet manifest
   path = "/etc/puppet/modules/web/files/web-manifests/balancer.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[Web monitor] Impossible to copy balancer manifest to #{vm}"
      return false
   end

   # Monitor load balancer with puppet
   # While god monitoring will be done in a loop this will only be done if
   # explicitly invoked, so we must call 'puppet apply' every time.
   command = "puppet apply /tmp/balancer.pp"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to run puppet in #{vm}"
      return false
   end
   
   return true
   
end


# Starts monitoring on web server.
def start_monitor_server(vm)

   # Copy the puppet manifest
   path = "/etc/puppet/modules/web/files/web-manifests/server.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[Web monitor] Impossible to copy server manifest to #{vm}"
      return false
   end
   
   # Monitor web servers with puppet: installation files and required gems
   command = "puppet apply /tmp/server.pp"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to run puppet in #{vm}"
      return false
   end
   
   # Monitor web servers with god: web server is up and running
   path = "/etc/puppet/modules/web/files/web-god/server.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "[Web monitor] Impossible to copy #{path} to #{vm}"
      return false
   end
   command = "god -c /etc/god/server.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to run god in #{vm}"
      return false
   end
   
   return true

end


# Starts monitoring on database.
def start_monitor_database(vm)

   # Monitor database with god due to puppet vs ubuntu mysql bug
   # http://projects.puppetlabs.com/issues/12773
   # Therefore there is no puppet monitoring, only god
   path = "/etc/puppet/modules/web/files/web-god/database.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to create /etc/god at #{vm}"
      return false
   end
   out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
   unless success
      err "[Web monitor] Impossible to copy #{path} to #{vm}"
      return false
   end
   command = "god -c /etc/god/database.god"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[Web monitor] Impossible to run god in #{vm}"
      return false
   end
   
   return true

end


################################################################################
# Stop functions
################################################################################

# Stops a web cloud.
def web_cloud_stop(web_roles)

   balancers = web_roles[:balancer]
   servers   = web_roles[:server]
   databases = web_roles[:database]

   # Stop services
   
   # Stop load balancers => Stop nginx
   puts "Stopping nginx on load balancers"
   balancers.each do |vm|
      stop_balancer(vm)
   end
   
   # Stop web servers => Stop sinatra application
   puts "Stopping ruby web3 on web servers"
   servers.each do |vm|
      stop_server(vm)
   end
   
   # Stop database servers => Stop mysql
   puts "Stopping mysql on database servers"
   databases.each do |vm|
      stop_database(vm)
   end

end


# Stops a load balancer.
def stop_balancer(vm)
command = "/etc/init.d/nginx start > /dev/null 2> /dev/null"

   # It is being monitored explicitly with puppet, so we do not have to stop
   # monitoring explicitly, we just have to stop it
   
   command = "/etc/init.d/nginx stop > /dev/null 2> /dev/null"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "Impossible to stop balancer in #{vm}"
      return false
   end

end


# Stops a web server.
def stop_server(vm)

   command = "pkill -f server.god"     # We are looking for server.god
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      command = "pkill -f web3"
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         err "Impossible to stop web server in #{vm}"
         return false
      end
   end

end


# Stops a database server.
def stop_database(vm)

   command = "pkill -f database.god"     # We are looking for database.god
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      command = "/usr/bin/service mysql stop"      # Do not kill it, stop it
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         err "Impossible to stop database in #{vm}"
         return false
      end
   end

end

