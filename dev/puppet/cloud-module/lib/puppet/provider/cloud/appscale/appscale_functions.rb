def appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                         app_email=nil, app_password=nil, root_password=nil)

   require 'pty'
   require 'expect'
   
   # Sample dialog
   # -------------
   # Enter your desired administrator e-mail address: david@mail.com
   # 
   # The new administrator password must be at least six characters long and \
   #   can include non-alphanumeric characters.
   # Enter your new password: 
   # Enter again to verify: 
   # Please wait for AppScale to prepare your machines for use.
   # Starting up XMPP server
   # 
   # Your user account has been created successfully.
   # 
   # Your user account has been created successfully.
   # No app uploaded. Use appscale-upload-app to upload an app later.
   # The status of your AppScale instance is at the following URL: \
   #   http://155.210.155.73/status
   # Your XMPP username is david@155.210.155.73
   
   # Check arguments
   puts "appscale_cloud_start called with:"
   puts "  - app_email == #{app_email}"
   puts "  - app_password == #{app_password}"
   puts "  - root_password == #{root_password}"
   
   ssh_connect = "#{ssh_user}@#{ssh_host}"
   bin_path = "/usr/local/appscale-tools/bin"
   
   # Add key pairs
   debug "[DBG] About to add key pairs"
   puts "=About to add key pairs"
   debug "[DBG] ips.yaml file: #{ips_yaml}"
   arguments = "--auto --ips #{ips_yaml} --cp_pass #{root_password}"
   if Facter.value(:ipaddress) == ssh_host
      # Do it local
      result = `#{bin_path}/appscale-add-keypair #{arguments}`
   else
      # Do it remote
      result = `#{ssh_connect} '#{bin_path}/appscale-add-keypair #{arguments}'`
   end
   puts result
   if $?.exitstatus == 0
      debug "[DBG] Key pairs added"
      puts "Key pairs added"
   else
      debug "[DBG] Impossible to add key pairs"
      err   "Impossible to add key pairs"
   end
   
   # Run instances
   debug "[DBG] About to run instances"
   puts "=About to run instances"
   puts "This may take a while (~ 3 min), so please be patient"
   arguments = "--ips #{ips_yaml} --cp_user #{app_email} --cp_pass #{app_password}"
   if Facter.value(:ipaddress) == ssh_host
      # Do it local
      result = `#{bin_path}/appscale-run-instances #{arguments}`
   else
      # Do it remote
      result = `#{ssh_connect} '#{bin_path}/appscale-run-instances #{arguments}`
   end
   puts result
   if $?.exitstatus == 0
      debug "[DBG] Instances running"
      puts  "Instances running"
   else
      debug "[DBG] Impossible to run appscale instances"
      err   "Impossible to run appscale instances"
   end
   
end
