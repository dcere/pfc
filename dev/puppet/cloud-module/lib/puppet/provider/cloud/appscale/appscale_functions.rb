# Starts an AppScale cloud.
def appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                         app_email=nil, app_password=nil, root_password=nil)

   require 'pty'
   require 'expect'
   
   # Check arguments
   puts "appscale_cloud_start called with:"
   puts "  - app_email == #{app_email}"
   puts "  - app_password == #{app_password}"
   puts "  - root_password == #{root_password}"
   
   ssh_connect = "ssh #{ssh_user}@#{ssh_host}"
   bin_path = "/usr/local/appscale-tools/bin"
   
   # Copy expect scripts
   puts "Copying expect scripts"
   #path = "/etc/puppet/modules/cloud/files"
   path = "./"
   script_keys = "appscale-add-keypair.tcl"
   script_run = "appscale-run-instances.tcl"
   if MY_IP != ssh_host
   
      # appscale-add-keypair.tcl expect script
      result = `scp #{path}/#{script_keys} #{ssh_user}@#{ssh_host}:#{path}/`
      if $?.exitstatus == 0
         puts "#{script_keys} copied"
      else
         err "Impossible to copy #{script_keys}"
      end
      
      # appscale-run-instances.tcl expect script
      result = `scp #{path}/#{script_run} #{ssh_user}@#{ssh_host}:#{path}/`
      if $?.exitstatus == 0
         puts "#{script_run} copied"
      else
         err "Impossible to copy #{script_run}"
      end
   end
   
   # Add key pairs
   puts "About to add key pairs"
   debug "[DBG] ips.yaml file: #{ips_yaml}"
   if MY_IP == ssh_host
      # Do it local
      result = `/root/#{script_keys} #{ips_yaml} #{root_password}`
      if $?.exitstatus == 0
         puts "Key pairs added"
      else
         err "Impossible to add key pairs"
      end
   else
      # Do it remote
      result = `#{ssh_connect} '/root/#{script_keys} #{ips_yaml} #{root_password}'`
      if $?.exitstatus == 0
         puts "Key pairs added"
      else
         err "Impossible to add key pairs"
      end
   end
   
   # Run instances
   puts "About to run instances"
   puts "This may take a while (~ 3 min), so please be patient"
   if MY_IP == ssh_host
      # Do it local
      result = `/root/#{script_run} #{ips_yaml} #{app_email} #{app_password}`
      if $?.exitstatus == 0
         puts "Instances running"
      else
         err "Impossible to run appscale instances"
      end
   else
      # Do it remote
      result = `#{ssh_connect} '/root/#{script_run} #{ips_yaml} #{app_email} #{app_password}'`
      if $?.exitstatus == 0
         puts "Instances running"
      else
         err "Impossible to run appscale instances"
      end
   end
   
end


# Monitors a virtual machine belonging to an AppScale cloud.
def appscale_monitor(vm, role)

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
