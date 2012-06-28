# Starts a virtual machine.
def start_vm(vm, ip_roles, img_roles, pm_up)

   # This function is cloud-type independent: define a new virtual machine and
   # start it
   
   # Get virtual machine's MAC address
   puts "Getting VM's MAC address..."
   if File.exists?(LAST_MAC_FILE)
      file = File.open(LAST_MAC_FILE, 'r')
      mac_address = MAC_Address.new(file.read().chomp())
      file.close
   else
      mac_address = MAC_Address.new(resource[:starting_mac_address])
   end
   mac_address = mac_address.next_mac()
   puts "...VM's MAC is #{mac_address}"
   
   # Get virtual machine's image disk
   puts "Getting VM's image disk..."
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
   puts "Image roles:"
   p img_roles
   disk = img_roles[role][index]
   puts "...VM's image disk is #{disk}"
   
   # Define new virtual machine
   id = rand(10000)      # Choose a number for domain name randomly
   vm_name = "myvm-#{id}"
   vm_uuid = `uuidgen`
   vm_mac  = mac_address
   vm_disk = disk
   vm_mem  = resource[:vm_mem]
   vm_ncpu = resource[:vm_ncpu]
   myvm = VM.new(vm_name, vm_uuid, vm_disk, vm_mac, vm_mem, vm_ncpu)
   
   # Write virtual machine's domain file
   require 'erb'
   template = File.open(resource[:vm_domain], 'r').read()
   erb = ERB.new(template)
   domain_file_name = "cloud-%s-%s.xml" % [resource[:name], vm_name]
   domain_file_path = "/etc/puppet/modules/#{resource[:name]}/files/#{domain_file_name}"
   domain_file = File.open(domain_file_path, 'w')
   debug "[DBG] Domain file created"
   domain_file.write(erb.result(myvm.get_binding))
   domain_file.close
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
      debug "[DBG] domain definition file copied"
   else
      debug "[DBG] #{vm_name} impossible to copy domain definition file"
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


# Define a domain for a virtual machine on a physical machine.
def define_domain(pm_user, pm, vm_name, domain_file_name)

   #result = `#{ssh_connect} '#{VIRSH_CONNECT} define #{domain_file_name}'`
   command = "#{VIRSH_CONNECT} define #{domain_file_name}"
   out, success = CloudSSH.execute_remote(command, pm_user, pm)
   if success
      debug "[DBG] #{vm_name} domain defined"
      return true
   else
      debug "[DBG] #impossible to define #{vm_name} domain"
      err   "#impossible to define #{vm_name} domain"
      return false
   end
   
end


# Starts a domain on a physical machine.
def start_domain(pm_user, pm, vm_name)

   #result = `#{ssh_connect} '#{VIRSH_CONNECT} start #{vm_name}'`
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

   #result = `#{ssh_connect} 'echo #{vm_name} >> #{DOMAINS_FILE}'`
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
