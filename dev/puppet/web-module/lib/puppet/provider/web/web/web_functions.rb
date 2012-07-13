# Starts a web cloud.
def web_cloud_start(resource, web_roles)

   balancers = web_roles[:balancer]
   servers   = web_roles[:server]
   databases = web_roles[:database]

   # Start services
   
   # Start load balancers => Start nginx
   puts "Starting nginx on load balancers"
   balancers.each do |vm|
      start_balancer(resource, vm)
   end
   
   # Start web servers => Start sinatra application
   puts "Starting ruby web3 on web servers"
   servers.each do |vm|
      start_server(resource, vm)
   end
   
   # Database servers start at boot time, but check whether they have started
   # and if they have not, start them
   puts "Starting mysql on database servers"
   databases.each do |vm|
      start_database(resource, vm)
   end
   
   
   # Start monitoring
   
   # Load balancers
   balancers.each do |vm|
      start_monitor_balancer(resource, vm)
   end
   
   # Web servers
   servers.each do |vm|
      start_monitor_server(resource, vm)
   end
   
   # Database servers
   databases.each do |vm|
      start_monitor_database(resource, vm)
   end
   
   return true
   
end


################################################################################
# Start node functions
################################################################################

# Starts a load balancer.
def start_balancer(resource, vm)
   
   command = "/etc/init.d/nginx start > /dev/null 2> /dev/null"
   user = resource[:vm_user]
   if vm == MY_IP
      result = `#{command}`
      unless $?.exitstatus == 0
         err "Impossible to start balancer in #{vm}"
         return false
      end
   else
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         err "Impossible to start balancer in #{vm}"
         return false
      end
   end

end


# Starts a web server.
def start_server(resource, vm)
   
   # The ruby-web3 file should have been already copied at this point. It should
   # have been copied when installing the web server.
   command = "/etc/init.d/ruby-web3 start"
   user = resource[:vm_user]
   if vm == MY_IP
      result = `#{command}`
      unless $?.exitstatus == 0
         err "Impossible to start server in #{vm}"
         return false
      end
   else
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         err "Impossible to start server in #{vm}"
         return false
      end
   end

end


# Starts a database server.
def start_database(resource, vm)
   
   check_command = "ps aux | grep -v grep | grep mysql"
   command = "/usr/bin/service mysql start"
   user = resource[:vm_user]
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
      out, success = CloudSSH.execute_remote(check_command, user, vm)
      unless success
         out, success = CloudSSH.execute_remote(command, user, vm)
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
def web_monitor(resource, vm, role)

   if role == :balancer
      puts "[Web monitor] Monitoring load balancer"
      
      # Run puppet
      unless start_monitor_balancer(resource, vm)
         puts "[Web monitor] Impossible to monitor load balancer on #{vm}"
      end
      puts "[Web monitor] Monitored load balancer"

   elsif role == :server
      puts "[Web monitor] Monitoring web server"
      
      # Run puppet
      unless start_monitor_server(resource, vm)
         puts "[Web monitor] Impossible to monitor web server on #{vm}"
      end
      
      puts "[Web monitor] Monitored web server"
      
   elsif role == :database
      puts "[Web monitor] Monitoring database"
      
      # Check god is running
      check_command = "ps aux | grep -v grep | grep god | grep database.god"
      user = resource[:vm_user]
      out, success = CloudSSH.execute_remote(check_command, user, vm)
      unless success
         puts "[Web monitor] God is not running in #{vm}"
         
         # Try to start monitoring again
         puts "[Web monitor] Starting monitoring database on #{vm}"
         if start_monitor_database(resource, vm)
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
def start_monitor_balancer(resource, vm)

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
   user = resource[:vm_user]
   out, success = CloudSSH.execute_remote(command, user, vm)
   unless success
      err "[Web monitor] Impossible to run puppet in #{vm}"
      return false
   end
   
   return true
   
end


# Starts monitoring on web server.
def start_monitor_server(resource, vm)

   # Copy the puppet manifests: general, start and stop
   path = "/etc/puppet/modules/web/files/web-manifests/server.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[Web monitor] Impossible to copy server manifest to #{vm}"
      return false
   end
   
   path = "/etc/puppet/modules/web/files/web-manifests/server-start.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[Web monitor] Impossible to copy server start manifest to #{vm}"
      return false
   end
   
   path = "/etc/puppet/modules/web/files/web-manifests/server-stop.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[Web monitor] Impossible to copy server stop manifest to #{vm}"
      return false
   end
   
   # Monitor web servers with puppet: installation files and required gems
   # command = "puppet apply /tmp/server.pp"
   # user = resource[:vm_user]
   # out, success = CloudSSH.execute_remote(command, user, vm)
   # unless success
   #    err "[Web monitor] Impossible to run puppet (server.pp) in #{vm}"
   #    return false
   # end
   cron_time = "*/1 * * * *"
   cron_command = "puppet apply /tmp/server.pp"
   cron_out = "/root/server.out"
   cron_err = "/root/server.err"
   cron_line = cron_time + " " + cron_command + " > " + cron_out + " 2> " + cron_err
   out, success = CloudCron.add_line(cron_line, user, vm)
   unless success
      err "[Web monitor] Impossible to put server.pp in crontab in #{vm}"
      return false
   end

   # Monitor web servers with puppet: web server is up and running
   # command = "puppet apply /tmp/server-start.pp"
   # user = resource[:vm_user]
   # out, success = CloudSSH.execute_remote(command, user, vm)
   # unless success
   #    err "[Web monitor] Impossible to run puppet (server-start.pp) in #{vm}"
   #    return false
   # end
   cron_time = "*/1 * * * *"
   cron_command = "puppet apply /tmp/server-start.pp"
   cron_out = "/root/server-start.out"
   cron_err = "/root/server-start.err"
   cron_line = cron_time + " " + cron_command + " > " + cron_out + " 2> " + cron_err
   out, success = CloudCron.add_line(cron_line, user, vm)
   unless success
      err "[Web monitor] Impossible to put server-start.pp in crontab in #{vm}"
      return false
   end
   
   return true

end


# Starts monitoring on database.
def start_monitor_database(resource, vm)

   user = resource[:vm_user]

   # Monitor database with god due to puppet vs ubuntu mysql bug
   # http://projects.puppetlabs.com/issues/12773
   # Therefore there is no puppet monitoring, only god
   path = "/etc/puppet/modules/web/files/web-god/database.god"
   command = "mkdir -p /etc/god"
   out, success = CloudSSH.execute_remote(command, user, vm)
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
   out, success = CloudSSH.execute_remote(command, user, vm)
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
def web_cloud_stop(resource, web_roles)

   balancers = web_roles[:balancer]
   servers   = web_roles[:server]
   databases = web_roles[:database]

   # Stop services
   
   # Stop load balancers => Stop nginx
   puts "Stopping nginx on load balancers"
   balancers.each do |vm|
      stop_balancer(resource, vm)
   end
   
   # Stop web servers => Stop sinatra application
   puts "Stopping ruby web3 on web servers"
   servers.each do |vm|
      stop_server(resource, vm)
   end
   
   # Stop database servers => Stop mysql
   puts "Stopping mysql on database servers"
   databases.each do |vm|
      stop_database(resource, vm)
   end

end


# Stops a load balancer.
def stop_balancer(resource, vm)

   # It is being monitored explicitly with puppet, so we do not have to stop
   # monitoring explicitly, we just have to stop it
   
   command = "/etc/init.d/nginx stop > /dev/null 2> /dev/null"
   user = resource[:vm_user]
   out, success = CloudSSH.execute_remote(command, user, vm)
   unless success
      err "Impossible to stop balancer in #{vm}"
      return false
   end

end


# Stops a web server.
def stop_server(resource, vm)

   # It is being monitored explicitly with puppet, so we do not have to stop
   # monitoring explicitly, we just have to stop it
   
   command = "/etc/init.d/ruby-web3 stop > /dev/null 2> /dev/null"
   user = resource[:vm_user]
   out, success = CloudSSH.execute_remote(command, user, vm)
   unless success
      err "Impossible to stop web server in #{vm}"
      return false
   end
   
end


# Stops a database server.
def stop_database(resource, vm)

   user = resource[:vm_user]

   command = 'pkill -f database\(.\)god'    # We are looking for database.god
   out, success = CloudSSH.execute_remote(command, user, vm)
   if success
      command = "/usr/bin/service mysql stop"      # Do not kill it, stop it
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         err "Impossible to stop database in #{vm}"
         return false
      end
   else
      err "Impossible to stop database monitoring in #{vm}"
   end

end

