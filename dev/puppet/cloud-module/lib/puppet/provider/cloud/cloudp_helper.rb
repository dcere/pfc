# Auxiliar functions

def monitor_vm(vm, ip_roles, img_roles)

   role = :role_must_be_defined_outside_the_loop
   ip_roles.each do |r, ips|
      ips.each do |ip|
         if vm == ip then role = r end
      end
   end
   
   # Depending on the type of cloud we will have to monitor different components
   if resource[:type] == "appscale"
      appscale_monitor(role)
   elsif resource[:type] == "web"
      web_monitor(role)
   elsif resource[:type] == "jobs"
      jobs_monitor(role)
   else
      err "[%s-%s]: Unrecognized type of cloud" % [__FILE__,__LINE__]
   end
         

end


def start_vm(vm, ip_roles, img_roles, pmachines_up)

   # This function is cloud-type independent: define a new virtual machine and
   # start it
   
   # Get virtual machine's ID
   puts "Getting VM's ID..."
   if File.exists?("/tmp/cloud-last-id")
      file = File.open("/tmp/cloud-last-id", 'r')
   else
      file = File.open("/tmp/cloud-id", 'r')
   end
   id = file.read().chomp()
   id += 1
   file.close
   puts "...VM's ID is #{id}"
   
   # Get virtual machine's MAC address
   puts "Getting VM's MAC address..."
   if File.exists?("/tmp/cloud-last-mac")
      file = File.open("/tmp/cloud-last-mac", 'r')
      mac_address = MAC_Address.new(file.read().chomp())
   else
      mac_address = MAC_Address.new("52:54:00:01:00:00")
   end
   mac_address = mac_address.next_mac()
   puts "...VM's MAC is #{mac_address}"
   
   # Get virtual machine's image disk
   puts "Getting VM's image disk..."
   ip_roles.each do |r, ips|
      index = 0
      ips.each do |ip|
         if vm == ip
            role = r
         else
            index += 1
         end
      end
   end
   disk = img_roles[role][index]
   puts "...VM's image disk is #{disk}"
   
   # Define new virtual machine
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
   #pm = "155.210.155.70"
   
   # Copy the domain definition file to the physical machine
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
   define_domain(ssh_connect, vm_name, domain_file_path)
   
   # Start the domain
   start_domain(ssh_connect, vm_name)
   
   # Save the domain's name
   save_domain_name(ssh_connect, vm_name)
   
   
   
   # Save the new virtual machine's ID
   file = File.open("/tmp/cloud-last-id", 'w')
   file.puts(id)
   file.close

end




################################################################################
# TODO: Move them out of here
def appscale_monitor(role)
   return
end

def web_monitor(role)
   puts "Monitoring #{role}"
   err "role should be a symbol" unless role.class != "Symbol"
   return
end

def jobs_monitor(role)
   return
end






################################################################################
# Auxiliar functions
################################################################################
def check_pool

   all_up = true
   machines_up = []
   machines_down = []
   machines = resource[:pool]
   machines.each do |machine|
      result = `ping -q -c 1 -w 4 #{machine}`
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


def save_domain_name(ssh_connect, vm_name)

   file = "/tmp/defined-domains-#{resource[:name]}"
   result = `#{ssh_connect} 'echo #{vm_name} >> #{file}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm_name} name saved"
      return true
   else
      debug "[DBG] #{vm_name} name impossible to save"
      err   "#{vm_name} name impossible to save"
      return false
   end
end


def leader_election_id(id, vm)

   file = "/tmp/cloud-id"
   result = `ssh root@#{vm} 'echo #{id} > #{file}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm} received leader election id"
      return true
   else
      debug "[DBG] #{vm} did not receive leader election id"
      err   "#{vm} did not receive leader election id"
      return false
   end
   
end


def leader_election_leader_id(id, vm)

   file = "/tmp/cloud-leader"
   result = `ssh root@#{vm} 'echo #{id} > #{file}'`
   if $?.exitstatus == 0
      debug "[DBG] #{vm} received leader election leader's id"
      return true
   else
      debug "[DBG] #{vm} did not receive leader election leader's id"
      err   "#{vm} did not receive leader election leader's id"
      return false
   end
   
end


def command_execution(ip_array, command, error_message)
   
   ip_array.each do |vm|
      result = `#{command}`
      unless $?.exitstatus == 0
         debug "[DBG] #{vm}: #{error_message}"
         err   "#{vm}: #{error_message}"
      end
   end

end
