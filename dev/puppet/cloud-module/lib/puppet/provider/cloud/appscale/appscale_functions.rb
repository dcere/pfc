# Starts an AppScale cloud.
def appscale_cloud_start(app_email=nil, app_password=nil, root_password=nil)

   require 'expect'
   
   # Check arguments
   puts "appscale_cloud_start called with:"
   puts "  - app_email == #{app_email}"
   puts "  - app_password == #{app_password}"
   puts "  - root_password == #{root_password}"
   
   script_keys = "appscale-add-keypair.tcl"
   script_run  = "appscale-run-instances.tcl"
   ips_yaml = resource[:ip_file]
   script_path = "/etc/puppet/modules/cloud/lib/puppet/provider/cloud/appscale"
   
   # Add key pairs
   puts "About to add key pairs"
   debug "[DBG] ips.yaml file: #{ips_yaml}"
   result = `#{script_path}/#{script_keys} #{ips_yaml} #{root_password}`
   if $?.exitstatus == 0
      puts "Key pairs added"
   else
      err "Impossible to add key pairs"
      exit
   end
   
   # Run instances
   puts "About to run instances"
   puts "This may take a while (~ 3 min), so please be patient"
   result = `#{script_path}/#{script_run} #{ips_yaml} #{app_email} #{app_password}`
   if $?.exitstatus == 0
      puts "Instances running"
      puts "result = #{result}"
   else
      err "Impossible to run appscale instances"
      exit
   end
   
end


# Stops an AppScale cloud.
def appscale_cloud_stop(vm)
   
   # Terminate instances
   command = "/root/appscale-tools/bin/appscale-terminate-instances"
   CloudSSH.execute_remote(command, vm)
   
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
