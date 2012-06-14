# Auxiliar functions for torque provider


# Obtains virtual machines' IP addresses, image disks and roles.
def obtain_vm_data
   
   vm_ips = []
   vm_ip_roles = []
   vm_img_roles = []
   puts "Obtaining torque cloud data"
   vm_ips, vm_ip_roles = torque_yaml_ips(resource[:ip_file])
   vm_img_roles = torque_yaml_images(resource[:img_file])
   return vm_ips, vm_ip_roles, vm_img_roles
         
end


# Monitors a virtual machine.
# Returns false if the machine is not alive.
def monitor_vm(vm, ip_roles)

   # Check if it is alive
   alive = CloudMonitor.ping(vm)
   unless alive
      err "#{vm} is not alive. Impossible to monitor"
      
      # If it is not alive there is no point in continuing
      return false
   end
   
   # Send it your ssh key
   # Your key was created when you turned into leader
   puts "Sending ssh key to #{vm}"
   password = resource[:root_password]
   out, success = CloudSSH.copy_ssh_key(vm, password)
   if success
      puts "ssh key sent"
   else
      err "ssh key impossible to send"
   end
   
   # Check if MCollective is installed and configured
   mcollective_installed = CloudMonitor.mcollective_installed(vm)
   unless mcollective_installed
      err "MCollective is not installed on #{vm}"
   end
   
   # Make sure MCollective is running.
   # We need this to ensure the leader election, so ensuring MCollective
   # is running can not be left to Puppet in their local manifest. It must be
   # done explicitly here and now.
   mcollective_running = CloudMonitor.mcollective_running(vm)
   unless mcollective_running
      err "MCollective is not running on #{vm}"
   end
   
   # TODO What if a machine has different roles?
   
   role = :undefined
   ip_roles.each do |r, ips|
      ips.each do |ip|
         if ip == vm then role = r end
      end
   end
   
   # Check if they have their ID
   # If they are running, but they do not have their ID:
   #   - Set their ID before they can become another leader.
   #   - Set also the leader's ID.
   success = CloudLeader.vm_check_id(vm)
   unless success
   
      # Set their ID (based on the last ID we defined)
      id = get_last_id()
      id += 1
      CloudLeader.vm_set_id(vm, id)
      set_last_id(id)
      
      # Set the leader's ID
      leader = CloudLeader.get_leader()
      CloudLeader.vm_set_leader(vm, leader)
      
      # Send the last ID to all nodes
      mcc = MCollectiveFilesClient.new("files")
      mcc.create_file(LAST_ID_FILE, id.to_s)
      #mcc.disconnect
   end
   
   # TODO Copy cloud files each time a machine is monitored?
   # TODO Copy files no matter what or check first if they have them?
   # Use copy_cloud_files if we copy no matter what. Modify it if we check
   
   # Depending on the type of cloud we will have to monitor different components
   torque_monitor(vm, role)
   
   return true
   
end


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
   myvm = VM.new(vm_name, vm_uuid, vm_disk, vm_mac)
   
   # Write virtual machine's domain file
   require 'erb'
   template = File.open(resource[:domain], 'r').read()
   erb = ERB.new(template)
   domain_file_name = "cloud-%s-%s.xml" % [resource[:name], vm_name]
   domain_file = File.open("/etc/puppet/modules/torque/files/#{domain_file_name}", 'w')
   debug "[DBG] Domain file created"
   domain_file.write(erb.result(myvm.get_binding))
   domain_file.close
   puts "Domain file written"
   
   # Choose a physical machine to host the virtual machine
   pm = pm_up[rand(pm_up.count)] # Choose randomly
   
   # Copy the domain definition file to the physical machine
   puts "Copying the domain definition file to the physical machine..."
   domain_file_path = "/tmp/" + domain_file_name
   pm_user = resource[:pm_user]
   command = "scp /etc/puppet/modules/torque/files/#{domain_file_name}" +
                " #{pm_user}@#{pm}:#{domain_file_path}"
   result = `#{command}`
   if $?.exitstatus == 0
      debug "[DBG] domain definition file copied"
   else
      debug "[DBG] #{vm_name} impossible to copy domain definition file"
      err   "#{vm_name} impossible to copy domain definition file"
   end
   
   ssh_connect = "ssh #{pm_user}@#{pm}"
   
   # Define the domain in the physical machine
   puts "Defining the domain in the physical machine..."
   define_domain(ssh_connect, vm_name, domain_file_path)
   
   # Start the domain
   puts "Starting the domain..."
   start_domain(ssh_connect, vm_name)
   
   # Save the domain's name
   puts "Saving the domain's name..."
   save_domain_name(ssh_connect, vm_name)
   
   # Save the new virtual machine's MAC address
   file = File.open(LAST_MAC_FILE, 'w')
   file.puts(mac_address)
   file.close
   
   # Send the new virtual machine's MAC address to all nodes
   mcc = MCollectiveFilesClient.new("files")
   mcc.create_file(LAST_MAC_FILE, mac_address)
   #mcc.disconnect

end


# Copies important files to all machines inside <ips>
def copy_cloud_files(ips)
# Use MCollective?
#  - Without MCollective we are able to send it to both one machine or multiple
#    machines without changing anything, so not really.

   ips.each do |vm|
   
      if vm != MY_IP
         
         # Cloud manifest
         file = "init-torque.pp"
         path = "/etc/puppet/modules/torque/manifests/#{file}"
         out, success = CloudSSH.copy_remote(path, vm, path)
         unless success
            err "Impossible to copy #{file} to #{vm}"
         end
         
         # Cloud description (IPs YAML file)
         out, success = CloudSSH.copy_remote(resource[:ip_file], vm, resource[:ip_file])
         unless success
            err "Impossible to copy #{resource[:ip_file]} to #{vm}"
         end
         
         # Cloud roles (Image disks YAML file)
         out, success = CloudSSH.copy_remote(resource[:img_file], vm, resource[:img_file])
         unless success
            err "Impossible to copy #{resource[:img_file]} to #{vm}"
         end
      end
   end
   
end


# Starts a cloud formed by <vm_ips> performing <vm_ip_roles>
def start_cloud(vm_ips, vm_ip_roles)

   puts "Starting the cloud"
   return torque_cloud_start(vm_ip_roles)

end


# Makes the cloud auto-manageable through crontab files.
def auto_manage()

   cron_file = "crontab-torque"
   path = "/etc/puppet/modules/torque/files/cron/#{cron_file}"
   
   if File.exists?(path)
      file = File.open(path, 'r')
      line = file.read().chomp()
      file.close
      
      # Add the 'puppet apply manifest.pp' line to the crontab file
      mcc = MCollectiveCronClient.new("cronos")
      mcc.add_line(CRON_FILE, line)
      mcc.disconnect
   else
      err "Impossible to find cron file at #{path}"
   end
   
end
