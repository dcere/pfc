################################################################################
# Auxiliar functions for torque provider
################################################################################

# The functions in this file are defined the same in all providers, but each
# one implements them in their own way. Thus, the headers cannot be modified.

# Starts a torque cloud formed by <vm_ips> performing <vm_ip_roles>.
def start_cloud(resource, vm_ips, vm_ip_roles)

   puts "Starting the cloud"

   # SSH keys have already been distributed when machines were monitorized,
   # so we do not have to distribute them again
   
   # Start torque cloud
   return torque_cloud_start(resource, vm_ip_roles)

end


# Obtains vm data from manifest parameters.
def obtain_vm_data(resource)

   puts "Obtaining virtual machines' data"
   return obtain_torque_data(resource[:head], resource[:compute])
   
end
