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
      id = file.read().chomp().to_i
      file.close
   else
      id = CloudLeader.get_id()
   end
   return id

end


# Sets last defined ID in the ID file.
def set_last_id(id)

   file = File.open(LAST_ID_FILE, 'w')
   file.puts(id)
   file.close
   
end
