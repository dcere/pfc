################################################################################
# Auxiliar functions for web provider
################################################################################

# Starts a web cloud formed by <vm_ips> performing <vm_ip_roles>
def start_cloud(vm_ips, vm_ip_roles)

   puts "Starting the cloud"
   puts  "Starting a web cloud"
   
   # SSH keys have already been distributed when machines were monitorized,
   # so we do not have to distribute them again
   
   # Start web cloud
   return web_cloud_start(vm_ip_roles)

end
