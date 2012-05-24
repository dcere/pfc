# Auxiliar functions for cloud provider


# Obtains virtual machines' IP addresses, image disks and roles.
def obtain_vm_data
   
   vm_ips = []
   vm_ip_roles = []
   vm_img_roles = []
   if resource[:type].to_s == "appscale"
      puts "It is an appscale cloud"
      vm_ips, vm_ip_roles = appscale_yaml_ips(resource[:ip_file])
      vm_img_roles = appscale_yaml_images(resource[:img_file])
   elsif resource[:type].to_s == "web"
      puts "It is a web cloud"
      vm_ips, vm_ip_roles = web_yaml_ips(resource[:ip_file])
      vm_img_roles = web_yaml_images(resource[:img_file])
   elsif resource[:type].to_s == "jobs"
      puts "It is a jobs cloud"
      vm_ips = []
      # ...
   else
      err "Cloud type undefined: #{resource[:type]}"
      err "Cloud type class: #{resource[:type].class}"
   end
   return vm_ips, vm_ip_roles, vm_img_roles
         
end


# Monitors a virtual machine.
def monitor_vm(vm, ip_roles, img_roles)

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
   CloudSSH.copy_ssh_key(vm, password)
   puts "ssh key sent"
   
   role = :role_must_be_defined_outside_the_loop
   ip_roles.each do |r, ips|
      ips.each do |ip|
         if vm == ip then role = r end
      end
   end
   
   # Check if they have their ID
   # If they are running, but they do not have their ID:
   #   - Set their ID before they can become another leader.
   #   - Set also the leader's ID.
   command = "cat #{ID_FILE} > /dev/null 2> /dev/null"
   out, success = CloudSSH.execute_remote(command, vm)
   unless success
      le = LeaderElection.new()
   
      # Set their ID (based on the last ID we defined)
      id = get_last_id()
      id += 1
      le.vm_set_id(vm, id)
      set_last_id(id)
      
      # Set the leader's ID
      leader = le.get_leader()
      le.vm_set_leader(vm, leader)
   end
   
   # Check if MCollective is installed and configured
   mcollective_installed = CloudMonitor.mcollective_installed(vm)
   unless mcollective_installed
      err "MCollective is not installed on #{vm}"
   end
   
   # Make sure MCollective is running. We need this to ensure the leader election,
   # so assuring MCollective is running can not be left to Puppet in their local
   # manifest. It must be done explicitly here and now.
   mcollective_running = CloudMonitor.mcollective_running(vm)
   unless mcollective_running
      err "MCollective is not running on #{vm}"
   end
   
   # Depending on the type of cloud we will have to monitor different components
   if resource[:type].to_s == "appscale"
      appscale_monitor(vm, role)
   elsif resource[:type].to_s == "web"
      web_monitor(vm, role)
   elsif resource[:type].to_s == "jobs"
      jobs_monitor(role)
   else
      err "Unrecognized type of cloud: #{resource[:type]}"
   end
   
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
      mac_address = MAC_Address.new("52:54:00:01:00:00")
   end
   mac_address = mac_address.next_mac()
   puts "...VM's MAC is #{mac_address}"
   
   # Get virtual machine's image disk
   puts "Getting VM's image disk..."
   role = :role_must_be_defined_outside_the_loop
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
   domain_file = File.open("/etc/puppet/modules/cloud/files/#{domain_file_name}", 'w')
   debug "[DBG] Domain file created"
   domain_file.write(erb.result(myvm.get_binding))
   domain_file.close
   puts "Domain file written"
   
   # Choose a physical machine to host the virtual machine
   pm = pm_up[rand(pm_up.count)] # Choose randomly
   
   # Copy the domain definition file to the physical machine
   puts "Copying the domain definition file to the physical machine..."
   domain_file_path = "/tmp/" + domain_file_name
   command = "scp /etc/puppet/modules/cloud/files/#{domain_file_name}" +
                " dceresuela@#{pm}:#{domain_file_path}"
   result = `#{command}`
   if $?.exitstatus == 0
      debug "[DBG] domain definition file copied"
   else
      debug "[DBG] #{vm_name} impossible to copy domain definition file"
      err   "#{vm_name} impossible to copy domain definition file"
   end
   
   ssh_connect = "ssh dceresuela@#{pm}"
   
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

end


# Copies important files to all machines inside <ips>
def copy_cloud_files(ips)
# Use MCollective?
#  - Without MCollective we are able to send it to both one machine or multiple
#    machines without changing anything, so not really.

   ips.each do |vm|
   
      if vm != MY_IP
         # Cloud manifest
         # FIXME : Check 'source' attribute in manifest to avoid scp
         file = "init-%s.pp" % [resource[:type].to_s]
         path = "/etc/puppet/modules/cloud/manifests/#{file}"
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
   if resource[:type].to_s == "appscale"
      if (resource[:app_email] == nil) || (resource[:app_password] == nil)
         err "Need an AppScale user and password"
         exit
      else
         puts "app_email = #{resource[:app_email]}"
         puts "app_password = #{resource[:app_password]}"
      end
      puts  "Starting an appscale cloud"
      
      puppet_path = "/etc/puppet/"
      appscale_manifest_path = puppet_path + "appscale_basic.pp"
      appscale_manifest = File.open("/etc/puppet/modules/cloud/files/appscale-manifests/basic.pp", 'r').read()
      puts "Creating manifest files on agent nodes"
      mcc = MCollectiveFilesClient.new("files")
      mcc.create_files(appscale_manifest_path, appscale_manifest)
      mcc.disconnect()
      puts "Manifest files created"
      
      # FIXME Only works if ssh keys are OK. Maybe Puppet source?
      #yaml_file = resource[:ip_file]
      #puts "Copying #{yaml_file} to 155.210.155.170:/tmp"
      #result = `scp #{yaml_file} root@155.210.155.170:/tmp`
      ips_yaml = File.basename(resource[:ip_file])
      ips_yaml = "/tmp/" + ips_yaml
      puts "Calling appscale_cloud_start"
      ssh_user = "root"
      ssh_host = "155.210.155.170"
      appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                           resource[:app_email], resource[:app_password],
                           resource[:root_password])

   elsif resource[:type].to_s == "web"
      puts  "Starting a web cloud"
      
      # SSH keys have already been distributed when machines were monitorized,
      # so we do not have to distribute them again
      
      # Start web cloud
      web_cloud_start(vm_ip_roles)

   elsif resource[:type].to_s == "jobs"
      debug "[DBG] Starting a jobs cloud"
      puts  "Starting a jobs cloud"
      jobs_cloud_start

   else
      debug "[DBG] Cloud type undefined: #{resource[:type]}"
      err   "Cloud type undefined: #{resource[:type]}"
   end


end


# Makes the cloud auto-manageable through crontab files.
def auto_manage()

   cron_file = "crontab-%s" % [resource[:type].to_s]
   path = "/etc/puppet/modules/cloud/files/cron/#{cron_file}"
   
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


################################################################################
# TODO: Move them out of here

def jobs_monitor(role)
   return
end


################################################################################
# Auxiliar functions
################################################################################

# Checks the pool of physical machines are OK.
def check_pool

   all_up = true
   machines_up = []
   machines_down = []
   machines = resource[:pool]
   machines.each do |machine|
      result = `#{PING} #{machine}`
      if $?.exitstatus == 0
         debug "[DBG] #{machine} (PM) is up"
         machines_up << machine
      else
         debug "[DBG] #{machine} (PM) is down"
         all_up = false
         machines_down << machine
      end
   end
   return all_up, machines_up, machines_down
end


# Define a domain for a virtual machine on a physical machine.
def define_domain(ssh_connect, vm_name, domain_file_name)

   result = `#{ssh_connect} '#{VIRSH_CONNECT} define #{domain_file_name}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm_name} domain defined"
      return true
   else
      debug "[DBG] #impossible to define #{vm_name} domain"
      err   "#impossible to define #{vm_name} domain"
      return false
   end
end


# Starts a domain on a physical machine.
def start_domain(ssh_connect, vm_name)

   result = `#{ssh_connect} '#{VIRSH_CONNECT} start #{vm_name}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm_name} started"
      return true
   else
      debug "[DBG] #{vm_name} impossible to start"
      err   "#{vm_name} impossible to start"
      return false
   end
end


# Saves the virtual machine's domain name in a file.
def save_domain_name(ssh_connect, vm_name)

   result = `#{ssh_connect} 'echo #{vm_name} >> #{DOMAINS_FILE}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm_name} name saved"
      return true
   else
      debug "[DBG] #{vm_name} name impossible to save"
      err   "#{vm_name} name impossible to save"
      return false
   end
end


################################################################################
# Last ID functions
################################################################################

# Gets the last defined ID in the ID file.
def get_last_id()

   if File.exists?(LAST_ID_FILE)
      file = File.open(LAST_ID_FILE, 'r')
   else
      file = File.open(ID_FILE, 'r')
   end
   id = file.read().chomp().to_i
   file.close
   return id

end


# Sets last defined ID in the ID file.
def set_last_id(id)

   file = File.open(LAST_ID_FILE, 'w')
   file.puts(id)
   file.close
   
end
