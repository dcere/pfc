################################################################################
# Auxiliar functions for appscale provider
################################################################################

# The functions in this file are defined the same in all providers, but each
# one implements them in their own way. Thus, the headers cannot be modified.

# Starts an AppScale cloud formed by <vm_ips> performing <vm_ip_roles>
def start_cloud(resource, vm_ips, vm_ip_roles)

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
   return appscale_cloud_start(resource, vm_ips, vm_ip_roles,
                               resource[:app_email], resource[:app_password],
                               resource[:root_password])

end


# Obtains vm data from manifest parameters.
def obtain_vm_data(resource)

   # Default deployment
   if resource[:controller] != nil && resource[:servers] != nil

      puts "Default deployment"
      return obtain_appscale_data_default(resource[:controller],
                                          resource[:servers])

   # Custom deployment
   elsif resource[:master] != nil && resource[:appengine] != nil &&
         resource[:database] != nil && resource[:login] != nil &&
         resource[:open] != nil

      puts "Custom deployment"
      return obtain_appscale_data_custom(resource[:master],
                                         resource[:appengine],
                                         resource[:database],
                                         resource[:login],
                                         resource[:open],
                                         resource[:zookeeper],
                                         resource[:memcache])

   end

#   ips, ip_roles = appscale_yaml_ips(resource[:ip_file])
#   img_roles     = appscale_yaml_ips(resource[:img_file])
#   return ips, ip_roles, img_roles
   
end
