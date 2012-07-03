# Constants
LAST_MAC_FILE = "/tmp/cloud-last-mac"


# Starts a virtual machine.
def start_vm(vm, ip_roles, img_roles, pm_up)

   # This function is cloud-type independent: define a new virtual machine and
   # start it
   
   # Get virtual machine's MAC address
   puts "Getting VM's MAC address"
   mac_address = get_vm_mac()
   
   # Get virtual machine's image disk
   puts "Getting VM's image disk"
   disk = get_vm_disk(vm, ip_roles, img_roles)
   
   # Define a new virtual machine
   id = rand(10000)      # Choose a number for domain name randomly
   vm_name = "myvm-#{id}"
   vm_uuid = `uuidgen`
   vm_mac  = mac_address
   vm_disk = disk
   vm_mem  = resource[:vm_mem]
   vm_ncpu = resource[:vm_ncpu]
   myvm = VM.new(vm_name, vm_uuid, vm_disk, vm_mac, vm_mem, vm_ncpu)
   
   # Write virtual machine's domain file
   domain_file_name = "cloud-%s-%s.xml" % [resource[:name], vm_name]
   domain_file_path = File.dirname(resource[:vm_domain]) + 
                      "/" + "#{domain_file_name}"
   write_domain(myvm, domain_file_path)
   puts "Domain file written"
   
   # Choose a physical machine to host the virtual machine
   pm = pm_up[rand(pm_up.count)] # Choose randomly
   
   # Copy ssh key to physical machine
   puts "Copying ssh key to physical machine"
   pm_user = resource[:pm_user]
   pm_password = resource[:pm_password]
   out, success = CloudSSH.copy_ssh_key(pm_user, pm, pm_password)
   
   # Copy the domain definition file to the physical machine
   puts "Copying the domain definition file to the physical machine..."
   domain_file_src = domain_file_path
   domain_file_dst = "/tmp/" + domain_file_name
   
   out, success = CloudSSH.copy_remote(domain_file_src, pm, domain_file_dst, pm_user)
   if success
      puts "domain definition file copied"
      
      # Delete the local copy
      File.delete(domain_file_src)
   else
      err   "#{vm_name} impossible to copy domain definition file"
   end
   
   # Define the domain in the physical machine
   puts "Defining the domain in the physical machine..."
   define_domain(pm_user, pm, vm_name, domain_file_dst)
   
   # Start the domain
   puts "Starting the domain..."
   start_domain(pm_user, pm, vm_name)
   
   # Save the domain's name
   puts "Saving the domain's name..."
   save_domain_name(pm_user, pm, vm_name)
   
   # Save the new virtual machine's MAC address
   file = File.open(LAST_MAC_FILE, 'w')
   file.puts(mac_address)
   file.close
   
   # Send the new virtual machine's MAC address to all nodes
   mcc = MCollectiveFilesClient.new("files")
   mcc.create_file(LAST_MAC_FILE, mac_address)
   #mcc.disconnect

end


################################################################################
# Auxiliar functions
################################################################################


# Gets the virtual machine's mac address.
def get_vm_mac()
   
   if File.exists?(LAST_MAC_FILE)
      file = File.open(LAST_MAC_FILE, 'r')
      mac = MAC_Address.new(file.read().chomp())
      mac_address = mac.next_mac()
      file.close
   else
      mac = MAC_Address.new(resource[:starting_mac_address])
      mac_address = mac.mac
   end
   
   return mac_address

end


# Gets the virtual machine's disk image.
def get_vm_disk(vm, ip_roles, img_roles)
   
   # TODO What if a machine has different roles?
   role = :undefined
   index = 0
   ip_roles.each do |r, ips|
      index_aux = 0      # Reset the index for each role
      ips.each do |ip|
         if vm == ip
            puts "vm: #{vm} == ip: #{ip}"
            role = r
            index = index_aux
            puts "role: #{role}"
         else
            index_aux += 1
         end
      end
   end
   
   puts "Finished iterating. role: #{role}, index: #{index}"
   disk = img_roles[role][index]
   
   return disk

end


# Writes the virtual machine's domain file.
def write_domain(virtual_machine, domain_file_path)

   require 'erb'
   template = File.open(resource[:vm_domain], 'r').read()
   erb = ERB.new(template)
   domain_file = File.open(domain_file_path, 'w')
   domain_file.write(erb.result(virtual_machine.get_binding))
   domain_file.close

end


# Defines a domain for a virtual machine on a physical machine.
def define_domain(pm_user, pm, vm_name, domain_file_name)

   command = "#{VIRSH_CONNECT} define #{domain_file_name}"
   out, success = CloudSSH.execute_remote(command, pm_user, pm)
   if success
      debug "[DBG] #{vm_name} domain defined"
      return true
   else
      err   "Impossible to define #{vm_name} domain"
      return false
   end
   
end


# Starts a domain on a physical machine.
def start_domain(pm_user, pm, vm_name)

   command = "#{VIRSH_CONNECT} start #{vm_name}"
   out, success = CloudSSH.execute_remote(command, pm_user, pm)
   if success
      debug "[DBG] #{vm_name} started"
      return true
   else
      debug "[DBG] #{vm_name} impossible to start"
      err   "#{vm_name} impossible to start"
      return false
   end
   
end


# Saves the virtual machine's domain name in a file.
def save_domain_name(pm_user, pm, vm_name)

   command = "echo #{vm_name} >> #{DOMAINS_FILE}"
   out, success = CloudSSH.execute_remote(command, pm_user, pm)
   if success
      debug "[DBG] #{vm_name} name saved"
      return true
   else
      debug "[DBG] #{vm_name} name impossible to save"
      err   "#{vm_name} name impossible to save"
      return false
   end
   
end


# Gets all the roles a node has.
def get_vm_roles(roles, vm)

   # The roles array is a map of roles - IP addresses. The 'IP addresses' value
   # can be either a single value or an array of values.
   
   vm_roles = []
   roles.each do |role, ips|
      if ips == vm
         vm_roles << role
      elsif ips.is_a?(Array) && ips.include?(vm)
         vm_roles << role
      end
   end
   return vm_roles

end
