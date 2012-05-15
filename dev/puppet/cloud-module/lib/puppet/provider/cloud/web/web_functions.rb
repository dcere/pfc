def web_cloud_start(web_roles)
   
   # Distribute manifests
   # TODO Factorize if possible: ssh and scp => 2 versions ?
   #      command_execution_scp and command_execution_ssh?
   #      ssh to itself? Does it work if keys are distributed? Should it make
   #        a clear distinction between ssh to itself or others?
   
   #result = `mc manifest-agent -T balancer_coll`
   balancers = web_roles[:balancer]
   path = "/etc/puppet/modules/cloud/files/web-manifests/balancer.pp"
   balancers.each do |vm|
      result = `scp #{path} root@#{vm}:/tmp`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to copy balancer manifest to #{vm}"
         err   "Impossible to copy balancer manifest to #{vm}"
      end
   end

   #result = `mc manifest-agent -T servers_coll`
   servers = web_roles[:server]
   path = "/etc/puppet/modules/cloud/files/web-manifests/server.pp"
   servers.each do |vm|
      result = `scp #{path} root@#{vm}:/tmp`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to copy server manifest to #{vm}"
         err   "Impossible to copy server manifest to #{vm}"
      end
   end
   
   #result = `mc manifest-agent -T database_coll`
   databases = web_roles[:database]
   path = "/etc/puppet/modules/cloud/files/web-manifests/database.pp"
   databases.each do |vm|
      result = `scp #{path} root@#{vm}:/tmp`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to copy database manifest to #{vm}"
         err   "Impossible to copy database manifest to #{vm}"
      end
   end
   
   
   # Start services
   
   # Start load balancers => Start nginx
   #result = `mc load-balancer-agent -T balancer_coll`
   puts "Starting nginx on load balancers"
   command = "/etc/init.d/nginx start"
   balancers.each do |vm|
      if vm == MY_IP
         result = `#{command}`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start balancer in #{vm}"
            err   "Impossible to start balancer in #{vm}"
         end
      else
         result = `ssh root@#{vm} '#{command}'`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start balancer in #{vm}"
            err   "Impossible to start balancer in #{vm}"
         end
      end
   end
   
   # Start web servers => Start sinatra application
   #result = `mc web-server-agent -T servers_coll`
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
         result = `ssh root@#{vm} '#{command}'`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start server in #{vm}"
            err   "Impossible to start server in #{vm}"
         end
      end
   end
   
   # Database servers start at boot time, but just in case
   puts "Starting mysql on database servers"
   command = "/usr/bin/service mysql start"
   databases.each do |vm|
      if vm == MY_IP
         result = `#{command}`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start database in #{vm} (might be already running)"
            err   "Impossible to start database in #{vm} (might be already running)"
         end
      else
         result = `ssh root@#{vm} '#{command}'`
         unless $?.exitstatus == 0
            debug "[DBG] Impossible to start database in #{vm} (might be already running)"
            err   "Impossible to start database in #{vm} (might be already running)"
         end
      end
   end
   
   
   # Start monitoring
   
   # Monitor web server with god
   path = "/etc/puppet/modules/cloud/files/web-monitor/server.god"
   servers.each do |vm|
      result = `ssh root@#{vm} 'mkdir -p /etc/god'`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to create /etc/god at #{vm}"
         err   "Impossible to create /etc/god at #{vm}"
      end
      result = `scp #{path} root@#{vm}:/etc/god/`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to copy #{path} to #{vm}"
         err   "Impossible to copy #{path} to #{vm}"
      end
       result = `ssh root@#{vm} 'god -c /etc/god/server.god'`
       unless $?.exitstatus == 0
          debug "[DBG] Impossible to run god in #{vm}"
          err   "Impossible to run god in #{vm}"
       end
   end
   
   # Monitor database with god due to puppet vs ubuntu mysql bug
   # http://projects.puppetlabs.com/issues/12773
   path = "/etc/puppet/modules/cloud/files/web-monitor/database.god"
   databases.each do |vm|
      result = `ssh root@#{vm} 'mkdir -p /etc/god'`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to create /etc/god at #{vm}"
         err   "Impossible to create /etc/god at #{vm}"
      end
      result = `scp #{path} root@#{vm}:/etc/god/`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to copy #{path} to #{vm}"
         err   "Impossible to copy #{path} to #{vm}"
      end
      result = `ssh root@#{vm} 'god -c /etc/god/database.god'`
      unless $?.exitstatus == 0
         debug "[DBG] Impossible to run god in #{vm}"
         err   "Impossible to run god in #{vm}"
      end
   end
   
end


def web_monitor(role)
   puts "Monitoring #{role}"
   err "role should be a symbol" unless role.class != "Symbol"
   return
end
