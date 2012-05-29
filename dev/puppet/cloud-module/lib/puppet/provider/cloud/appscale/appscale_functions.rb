# Starts an AppScale cloud.
def appscale_cloud_start(app_ips, app_roles,
                         app_email=nil, app_password=nil, root_password=nil)

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
      return
   end
   
   # Run instances
   puts "About to run instances"
   puts "This may take a while (~ 5 min), so please be patient"
   result = `#{script_path}/#{script_run} #{ips_yaml} #{app_email} #{app_password}`
   if $?.exitstatus == 0
      puts "Instances running"
      puts "result = #{result}"
   else
      err "Impossible to run appscale instances"
      return
   end
   
   # Start monitoring
   puts "Start monitoring"
   app_ips.each do |vm|
   
      # Find the role
      # TODO What if a machine has different roles?
      role = :undefined
      app_roles.each do |r, ips|
         ips.each do |ip|
            if vm == ip then role = r end
         end
      end
      puts "Calling appscale_monitor"
      appscale_monitor(vm, role)
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

   command = "ps aux"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[AppScale monitor] Impossible to execute #{command} in #{vm}"
      return false
   end
   
   # AppMonitoring calls god, so look fot god processes
   if out.include? "/usr/bin/god"
   
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
         
         # Try to start the AppMonitoring
         puts "[AppScale monitor] Starting AppMonitoring on #{vm}"
         command = "/etc/init.d/appscale-monitoring start"
         out, success = CloudSSH.execute_remote(command, vm)
         if success
            puts "[AppScale monitor] Successfully started AppMonitoring"
         else
            err "[AppScale monitor] Impossible to start AppMonitoring in #{vm}"
            return false
         end
         

      else
      
         # AppController is not running
         puts "[AppScale monitor] AppController is not running"
         
         # Try to start the AppController
         puts "[AppScale monitor] Starting AppController on #{vm}"
         command = "/etc/init.d/appscale-controller start"
         out, success = CloudSSH.execute_remote(command, vm)
         if success
            puts "[AppScale monitor] Successfully started AppController"
         else
            err "[AppScale monitor] Impossible to start AppController in #{vm}"
            return false
         end
         
         # Try to start the AppMonitoring
         puts "[AppScale monitor] Starting AppMonitoring on #{vm}"
         command = "/etc/init.d/appscale-monitoring start"
         out, success = CloudSSH.execute_remote(command, vm)
         if success
            puts "[AppScale monitor] Successfully started AppMonitoring"
         else
            err "[AppScale monitor] Impossible to start AppMonitoring in #{vm}"
            return false
         end
         
      end
      
   end
   
   # If we have made it so far, let's try to apply the manifest
   
   # Copy the manifest
   puts "Copying manifest"
   path = "/etc/puppet/modules/cloud/files/appscale-manifests/basic.pp"
   out, success = CloudSSH.copy_remote(path, vm, "/tmp")
   unless success
      err "[AppScale monitor] Impossible to copy basic manifest to #{vm}"
      return false
   end
   
   # Apply the manifest
   puts "Applying manifest"
   command = "puppet apply /tmp/basic.pp"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      err "[AppScale monitor] Impossible to run puppet in #{vm}"
      return false
   end
   
end
