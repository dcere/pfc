class CloudInterface

   def initialize()
   end

   # The functions in this file are defined the same in all providers, but each
   # one implements them in their own way. Thus, the headers cannot be modified.

   # Starts a cloud formed by <vm_ips> performing <vm_ip_roles>.
   def start_cloud(resource, vm_ips, vm_ip_roles)

      puts "Starting the cloud"
      
      # ...

   end


   # Obtains vm data from manifest parameters.
   def obtain_vm_data(resource)

      puts "Obtaining virtual machines' data"
      
      # ...
      
   end
   
end
