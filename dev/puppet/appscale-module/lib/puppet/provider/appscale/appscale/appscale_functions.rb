# Starts an AppScale cloud.
def appscale_cloud_start(resource, app_ips, app_roles,
                         app_email=nil, app_password=nil, root_password=nil)

   require 'expect'
   
   # Check arguments
   puts "appscale_cloud_start called with:"
   puts "  - app_email == #{app_email}"
   puts "  - app_password == #{app_password}"
   puts "  - root_password == #{root_password}"
   
   script_keys = "appscale-add-keypair.tcl"
   script_run  = "appscale-run-instances.tcl"
   #ips_yaml = resource[:ip_file]
   script_path = "/etc/puppet/modules/appscale/lib/puppet/provider/appscale/appscale"

   # Write ips.yaml file
   puts "Writing AppScale ips_yaml file"
   puts "Hash received: "
   p app_roles
   ips_yaml = "/etc/puppet/modules/appscale/files/auto-ips.yaml"
   appscale_write_yaml_file(app_roles, ips_yaml)
   puts "AppScale ips_yaml file written"

   # Add key pairs
   puts "About to add key pairs"
   result = `#{script_path}/#{script_keys} #{ips_yaml} #{root_password}`
   if $?.exitstatus == 0
      puts "Key pairs added"
      puts "result = |||#{result}|||"
   else
      err "Impossible to add key pairs"
      return false
   end
   
   # Run instances
   puts "About to run instances"
   puts "This may take a while (~ 5 min), so please be patient"
   result = `#{script_path}/#{script_run} #{ips_yaml} #{app_email} #{app_password}`
   if $?.exitstatus == 0
      puts "Instances running"
      puts "result = |||#{result}|||"
   else
      err "Impossible to run appscale instances"
      return false
   end
   
   # Start monitoring
   puts "Start monitoring"
   app_ips.each do |vm|
   
      # Find the role
      # TODO What if a machine has different roles?
      # role = :undefined
      # app_roles.each do |r, ips|
      #    ips.each do |ip|
      #       if vm == ip then role = r end
      #    end
      # end

      # Get all vm's roles
      roles = app_roles.select { |r, ips| ips.include?(vm) }      # Be careful,
      # Ruby 1.8.7 returns an array instead of a hash, so we get something like
      # [[:appengine, [2, 3, 4]], [:database, [3, 4]]] which is an array of
      # arrays with the role in the first place of the innermost arrays.
      
      # Monitor every one of them
      roles.each do |role_array|
         role = role_array[0]
         puts "Calling appscale_monitor on #{vm} as #{role}"
         appscale_monitor(resource, vm, role)
      end
   end

   return true
   
end


# Stops an AppScale cloud.
def appscale_cloud_stop(resource, vm)
   
   user = resource[:vm_user]
   
   # Terminate instances
   command = "/root/appscale-tools/bin/appscale-terminate-instances"
   CloudSSH.execute_remote(command, user, vm)
   
end


# Monitors a virtual machine belonging to an AppScale cloud.
def appscale_monitor(resource, vm, role)

   command = "ps aux"
   user = resource[:vm_user]
   out, success = CloudSSH.execute_remote(command, user, vm)
   unless success
      err "[AppScale monitor] Impossible to execute #{command} in #{vm}"
      return
   end
   
   # AppMonitoring calls god, so look for god processes who look like this:
   # /usr/bin/ruby1.8 /usr/bin/god -c /root/appscale/AppMonitoring/config/global.god
   if out.include? "/usr/bin/god -c /root/appscale/AppMonitoring"
   
      # AppMonitoring is running
      puts "[AppScale monitor] AppMonitoring is running"

      # Check the appscale controller is running
      if out.include? "AppController/djinnServer.rb"
         
         # Everything looks right so let AppScale handle it
         puts "[AppScale monitor] AppController is running"
      
      else
         
         # If AppMonitoring is running but the AppController is not,
         # AppMonitoring will take care
         puts "[AppScale monitor] AppMonitoring will take care of AppController"
         
      end

   else
   
      # AppMonitoring is not running
      puts "[AppScale monitor] AppMonitoring is not running"
   
      if out.include? "AppController/djinnServer.rb"

         # AppController is running
         puts "[AppScale monitor] AppController is running"
         
      end
      
      # Try to start the AppMonitoring
      puts "[AppScale monitor] Starting AppMonitoring on #{vm}"
      command = "/etc/init.d/appscale-monitoring start"
      out, success = CloudSSH.execute_remote(command, user, vm)
      if success
         puts "[AppScale monitor] Successfully started AppMonitoring"
      else
         err "[AppScale monitor] Impossible to start AppMonitoring in #{vm}"
         return
      end
      
      # Since the AppMonitoring will take care of the AppController, we do
      # not have to start the AppController
      
      
   end
   
   # If we have made it so far, let's try to apply the manifest
   
   # Copy the manifest
   puts "Copying manifest"
   path = "/etc/puppet/modules/appscale/files/appscale-manifests/basic.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[AppScale monitor] Impossible to copy basic manifest to #{vm}"
      return
   end
   
   # Apply the manifest
   puts "Applying manifest"
   command = "puppet apply /tmp/basic.pp"
   out, success = CloudSSH.execute_remote(command, user, vm)
   unless success
      err "[AppScale monitor] Impossible to run puppet in #{vm}"
      return
   end
   
   # Analyze the output
   if out.include? "should be directory (noop)"
      err "[AppScale monitor] Missing directory in #{vm}"
      puts out
      return
   end
   
end


################################################################################
# Auxiliar functions
################################################################################

def err(text)
   puts "\e[31m#{text}\e[0m"
end

