def appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                         app_email=nil, app_password=nil, root_password=nil)

   require 'pty'
   require 'expect'
   
   # Check arguments
   puts "appscale_cloud_start called with:"
   puts "  - app_email == #{app_email}"
   puts "  - app_password == #{app_password}"
   puts "  - root_password == #{root_password}"
   
   ssh_connect = "#{ssh_user}@#{ssh_host}"
   bin_path = "/usr/local/appscale-tools/bin"
   
   # Add key pairs
   puts "About to add key pairs"
   debug "[DBG] ips.yaml file: #{ips_yaml}"
   #arguments = "--auto --ips #{ips_yaml} --cp_pass #{root_password}"
   if MY_IP == ssh_host
      # Do it local
      #result = `#{bin_path}/appscale-add-keypair #{arguments}`
      result = `/root/appscale-add-keypair.sh #{ips_yaml} #{root_password}`
   else
      # Do it remote
      #result = `#{ssh_connect} '#{bin_path}/appscale-add-keypair #{arguments}'`
      result = `#{ssh_connect} '/root/appscale-add-keypair.sh #{ips_yaml} #{root_password}'`
   end
   #puts result
   if $?.exitstatus == 0
      puts "Key pairs added"
   else
      err "Impossible to add key pairs"
   end
   
   # Run instances
   puts "About to run instances"
   puts "This may take a while (~ 3 min), so please be patient"
   #arguments = "--ips #{ips_yaml} --cp_user #{app_email} --cp_pass #{app_password}"
   if MY_IP == ssh_host
      # Do it local
      #result = `#{bin_path}/appscale-run-instances #{arguments}`
      result = `/root/appscale-run-instances.sh #{ips_yaml} #{app_email} #{app_password}`
   else
      # Do it remote
      #result = `#{ssh_connect} '#{bin_path}/appscale-run-instances #{arguments}`
      result = `#{ssh_connect} '/root/appscale-run-instances.sh #{ips_yaml} #{app_email} #{app_password}'`
   end
   #puts result
   if $?.exitstatus == 0
      debug "[DBG] Instances running"
      puts  "Instances running"
   else
      debug "[DBG] Impossible to run appscale instances"
      err   "Impossible to run appscale instances"
   end
   
end
