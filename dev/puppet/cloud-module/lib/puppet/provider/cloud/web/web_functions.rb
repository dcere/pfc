# Starts a web cloud.
def web_cloud_start(web_roles)
   
   # Distribute manifests
   #      ssh to itself? Does it work if keys are distributed? Should it make
   #        a clear distinction between ssh to itself or others?
   
   balancers = web_roles[:balancer]
   path = "/etc/puppet/modules/cloud/files/web-manifests/balancer.pp"
   balancers.each do |vm|
      out, success = CloudSSH.copy_remote(path, vm, "/tmp")
      unless success
         debug "[DBG] Impossible to copy balancer manifest to #{vm}"
         err   "Impossible to copy balancer manifest to #{vm}"
      end
   end

   servers = web_roles[:server]
   path = "/etc/puppet/modules/cloud/files/web-manifests/server.pp"
   servers.each do |vm|
      out, success = CloudSSH.copy_remote(path, vm, "/tmp")
      unless success
         debug "[DBG] Impossible to copy server manifest to #{vm}"
         err   "Impossible to copy server manifest to #{vm}"
      end
   end
   
   databases = web_roles[:database]
   path = "/etc/puppet/modules/cloud/files/web-manifests/database.pp"
   databases.each do |vm|
      out, success = CloudSSH.copy_remote(path, vm, "/tmp")
      unless success
         debug "[DBG] Impossible to copy database manifest to #{vm}"
         err   "Impossible to copy database manifest to #{vm}"
      end
   end
   
   
   # Start services
   
   # Start load balancers => Start nginx
   puts "Starting nginx on load balancers"
   command = "/etc/init.d/nginx start > /dev/null 2> /dev/null"
   balancers.each do |vm|
      if vm == MY_IP
         result = `#{command}`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start balancer in #{vm}"
            err   "Impossible to start balancer in #{vm}"
         end
      else
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            debug "[DBG] Impossible to start balancer in #{vm}"
            err   "Impossible to start balancer in #{vm}"
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
            debug "[DBG] Impossible to start server in #{vm}"
            err   "Impossible to start server in #{vm}"
         end
      else
         out, success = CloudSSH.execute_remote(command, vm)
         unless success
            debug "[DBG] Impossible to start server in #{vm}"
            err   "Impossible to start server in #{vm}"
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
               debug "[DBG] Impossible to start database in #{vm}"
               err   "Impossible to start database in #{vm}"
            end
         end
      else
         out, success = CloudSSH.execute_remote(check_command, vm)
         unless success
            out, success = CloudSSH.execute_remote(command, vm)
            unless success
               debug "[DBG] Impossible to start database in #{vm}"
               err   "Impossible to start database in #{vm}"
            end
         end
      end
   end
   
   
   # Start monitoring
   
   # Monitor web server with god
   path = "/etc/puppet/modules/cloud/files/web-god/server.god"
   servers.each do |vm|
      command = "mkdir -p /etc/god"
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         debug "[DBG] Impossible to create /etc/god at #{vm}"
         err   "Impossible to create /etc/god at #{vm}"
      end
      out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
      unless success
         debug "[DBG] Impossible to copy #{path} to #{vm}"
         err   "Impossible to copy #{path} to #{vm}"
      end
      command = "god -c /etc/god/server.god"
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         debug "[DBG] Impossible to run god in #{vm}"
         err   "Impossible to run god in #{vm}"
      end
   end
   
   # Monitor database with god due to puppet vs ubuntu mysql bug
   # http://projects.puppetlabs.com/issues/12773
   path = "/etc/puppet/modules/cloud/files/web-god/database.god"
   databases.each do |vm|
      command = "mkdir -p /etc/god"
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         debug "[DBG] Impossible to create /etc/god at #{vm}"
         err   "Impossible to create /etc/god at #{vm}"
      end
      out, success = CloudSSH.copy_remote(path, vm, "/etc/god")
      unless success
         debug "[DBG] Impossible to copy #{path} to #{vm}"
         err   "Impossible to copy #{path} to #{vm}"
      end
      command = "god -c /etc/god/database.god"
      out, success = CloudSSH.execute_remote(command, vm)
      unless success
         debug "[DBG] Impossible to run god in #{vm}"
         err   "Impossible to run god in #{vm}"
      end
   end
   
end


# Monitors a virtual machine belonging to a web cloud.
def web_monitor(vm, role)

   puts "Monitoring #{role}"
   err "role should be a symbol" unless role.class != "Symbol"
   result = `#{PING} #{vm}`
   if $?.exitstatus == 0
      puts "#{vm} is up"
   else
      puts "#{vm} is down"
   end
   return
   
end
