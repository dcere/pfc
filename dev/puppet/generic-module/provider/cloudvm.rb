# Manages the virtual machines that form a cloud.
class CloudVM

   # Constants
   LAST_MAC_FILE = "/tmp/cloud-last-mac"


   def initialize(infrastructure, leader, resource, error_function)

      @infrastructure = infrastructure
      @leader         = leader
      @resource       = resource
      @err            = error_function

   end


   # Defines and starts a virtual machine.
   def start_vm(vm, ip_roles, img_roles, pm_up)
      
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
      vm_mem  = @resource[:vm_mem]
      vm_ncpu = @resource[:vm_ncpu]
      myvm = VM.new(vm_name, vm_uuid, vm_disk, vm_mac, vm_mem, vm_ncpu)
      
      # Write virtual machine's domain file
      domain_file_name = "cloud-%s-%s.xml" % [@resource[:name], vm_name]
      domain_file_path = File.dirname(@resource[:vm_domain]) + 
                         "/" + "#{domain_file_name}"
      template_path = @resource[:vm_domain]
      CloudInfrastructure.write_domain(myvm, domain_file_path, template_path)
      puts "Domain file written"
      
      # Choose a physical machine to host the virtual machine
      pm = pm_up[rand(pm_up.count)] # Choose randomly
      
      # Copy ssh key to physical machine
      puts "Copying ssh key to physical machine"
      pm_user = @resource[:pm_user]
      pm_password = @resource[:pm_password]
      out, success = CloudSSH.copy_ssh_key(pm_user, pm, pm_password)
      
      # Copy the domain definition file to the physical machine
      puts "Copying the domain definition file to the physical machine..."
      domain_file_src = domain_file_path
      domain_file_dst = "/tmp/" + domain_file_name
      
      out, success = CloudSSH.copy_remote(domain_file_src, pm, domain_file_dst,
                                          pm_user)
      if success
         puts "domain definition file copied"
         
         # Delete the local copy
         File.delete(domain_file_src)
      else
         @err.call "Impossible to copy #{vm_name}\'s domain definition file"
      end
      
      # Define the domain in the physical machine
      puts "Defining the domain in the physical machine..."
      unless @infrastructure.define_domain(domain_file_dst, pm_user, pm)
         @err.call "Impossible to define #{vm_name} domain"
      end
      
      # Start the domain
      puts "Starting the domain..."
      unless @infrastructure.start_domain(vm_name, pm_user, pm)
         @err.call "#{vm_name} impossible to start"
      end
      
      # Save the domain's name
      puts "Saving the domain's name..."
      unless @infrastructure.save_domain_name(vm_name, pm_user, pm)
         @err.call "#{vm_name} impossible to save in domains file"
      end

      # Save the new virtual machine's MAC address
      file = File.open(LAST_MAC_FILE, 'w')
      file.puts(mac_address)
      file.close
      
      # Send the new virtual machine's MAC address to all nodes
      mcc = MCollectiveFilesClient.new("files")
      mcc.create_file(LAST_MAC_FILE, mac_address)
      #mcc.disconnect

   end


   # Monitors a virtual machine.
   # Returns false if the machine is not alive.
   def monitor_vm(vm, ip_roles, monitor_function)

      # Check if it is alive
      alive = CloudMonitor.ping(vm)
      unless alive
         @err.call "#{vm} is not alive. Impossible to monitor"
         
         # If it is not alive there is no point in continuing
         return false
      end
      
      # Get user and password
      user = @resource[:vm_user]
      password = @resource[:root_password]
      
      # Send it your ssh key
      # Your key was created when you turned into leader
      puts "Sending ssh key to #{vm}"
      out, success = CloudSSH.copy_ssh_key(user, vm, password)
      if success
         puts "ssh key sent"
      else
         @err.call "ssh key impossible to send"
      end
      
      # Check if MCollective is installed and configured
      mcollective_installed = CloudMonitor.mcollective_installed(user, vm)
      unless mcollective_installed
         @err.call "MCollective is not installed on #{vm}"
      end
      
      # Make sure MCollective is running.
      # We need this to ensure the leader election, so ensuring MCollective
      # is running can not be left to Puppet in their local manifest. It must be
      # done explicitly here and now.
      mcollective_running = CloudMonitor.mcollective_running(user, vm)
      unless mcollective_running
         @err.call "MCollective is not running on #{vm}"
      end
      
      # A node may have different roles
      vm_roles = get_vm_roles(ip_roles, vm)
      
      
      # Check if they have their ID
      # If they are running, but they do not have their ID:
      #   - Set their ID before they can become another leader.
      #   - Set also the leader's ID.
      success = CloudLeader.vm_check_id(user, vm)
      unless success
      
         # Set their ID (based on the last ID we defined)
         id = @leader.last_id
         id += 1
         CloudLeader.vm_set_id(user, vm, id)
         @leader.set_last_id(id)
         
         # Set the leader's ID
         leader = @leader.leader
         CloudLeader.vm_set_leader(user, vm, leader)
         
         # Send the last ID to all nodes
         mcc = MCollectiveFilesClient.new("files")
         mcc.create_file(CloudLeader::LAST_ID_FILE, id.to_s)
         #mcc.disconnect
      end
      
      # TODO Copy cloud files each time a machine is monitored?
      # TODO Copy files no matter what or check first if they have them?
      # Use copy_cloud_files if we copy no matter what. Modify it if we check
      # We should copy no matter what in case they have changed
      
      # Depending on the type of cloud we will have to monitor different components.
      # Also, take into account that one node can perform more than one role.
      print "#{vm} will perform the roles: "
      p vm_roles
      vm_roles.each do |role|
         monitor_function.call(@resource, vm, role)
      end
      
      return true
      
   end

   #############################################################################
   # Auxiliar functions
   #############################################################################
   private

   # Gets the virtual machine's mac address.
   def get_vm_mac()
      
      if File.exists?(LAST_MAC_FILE)
         file = File.open(LAST_MAC_FILE, 'r')
         mac = MAC_Address.new(file.read().chomp())
         mac_address = mac.next_mac()
         file.close
      else
         mac = MAC_Address.new(@resource[:starting_mac_address])
         mac_address = mac.mac
      end
      
      return mac_address

   end


   # Gets the virtual machine's disk image.
   def get_vm_disk(vm, ip_roles, img_roles)
      
      # TODO What if a machine has different roles?
      # Is it really a problem? Pick one of the images and that is it
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


end