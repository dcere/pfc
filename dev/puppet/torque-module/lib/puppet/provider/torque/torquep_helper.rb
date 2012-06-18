################################################################################
# Auxiliar functions
################################################################################

# Starts a cloud formed by <vm_ips> performing <vm_ip_roles>.
def start_cloud(vm_ips, vm_ip_roles)

   puts "Starting the cloud"
   return torque_cloud_start(vm_ip_roles)

end
