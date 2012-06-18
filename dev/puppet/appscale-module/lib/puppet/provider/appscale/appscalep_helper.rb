################################################################################
# Auxiliar functions for appscale provider
################################################################################

# Starts an AppScale cloud formed by <vm_ips> performing <vm_ip_roles>
def start_cloud(vm_ips, vm_ip_roles)

   puts "Starting the cloud"
   if (resource[:app_email] == nil) || (resource[:app_password] == nil)
      err "Need an AppScale user and password"
      exit
   else
      puts "app_email = #{resource[:app_email]}"
      puts "app_password = #{resource[:app_password]}"
   end
   puts  "Starting an appscale cloud"
   
   # Start appscale cloud
   return appscale_cloud_start(vm_ips, vm_ip_roles,
                               resource[:app_email], resource[:app_password],
                               resource[:root_password])

end
