# Auxiliar functions for torque provider

################################################################################
# Start cloud functions
################################################################################

# Starting function for leader node.
def leader_start(vm_ips, vm_ip_roles, vm_img_roles, pm_up)
   
   # We are the leader
   puts "#{MY_IP} is the leader"
   
   # Check wether virtual machines are alive or not
   alive = {}
   vm_ips.each do |vm|
      alive[vm] = false
   end
   
   puts "Checking whether virtual machines are alive..."
   vm_ips.each do |vm|
      result = `#{PING} #{vm}`
      if $?.exitstatus == 0
         debug "[DBG] #{vm} is up"
         alive[vm] = true
      else
         debug "[DBG] #{vm} is down"
         puts "#{vm} is down"
      end
   end
   
   # Monitor the alive machines. Start and configure the dead ones.
   deads = false
   vm_ips.each do |vm|
      if alive[vm]
         # If they are alive, monitor them
         puts "Monitoring #{vm}..."
         monitor_vm(vm, vm_ip_roles)
         puts "...Monitored"
      else
         # If they are not alive, start and configure them
         puts "Starting #{vm}..."
         start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
         puts "...Started"
         deads = true
      end
   end
   
   # Wait for all machines to be started
   unless deads
   
      # If not already started, start the cloud
      unless File.exists?("/tmp/cloud-#{resource[:name]}")
         
         # Copy important files to all machines
         puts "Copying important files to all virtual machines"
         copy_cloud_files(vm_ips, "torque")      # TODO Move it to monitor and call it each time for one vm?
      
         # Start the cloud
         if start_cloud(vm_ips, vm_ip_roles)
            
            # Make cloud nodes manage themselves
            #auto_manage("torque")     # Only if cloud was started properly FIXME Uncomment after tests
            
            # Create file
            cloud_file = File.open("/tmp/cloud-#{resource[:name]}", 'w')
            cloud_file.puts(resource[:name])
            cloud_file.close
            
            puts "==================="
            puts "== Cloud started =="
            puts "==================="
         else
            puts "Impossible to start cloud"
         end
      end      # unless File
      
   end      # unless deads

end


# Starting function for common (non-leader) nodes.
def common_start(my_id)

   # We are not the leader or we have not received our ID yet
   puts "#{MY_IP} is not the leader"

   if my_id == -1
      
      # If we have not received our ID, let's assume we will be the leader
      CloudLeader.set_id(0)
      CloudLeader.set_leader(0)
      
      puts "#{MY_IP} will be the leader"
      
      # Create your ssh key
      CloudSSH.generate_ssh_key()
      
   else
      
      # If we have received our ID, try to become leader
      puts "Trying to become leader..."
      
      # Get your ID
      #my_id = CloudLeader.get_id()
      
      # Get all machines' IDs
      mcc = MCollectiveLeaderClient.new("leader")
      ids = mcc.ask_id()
      
      # See if some other machine is leader
      exists_leader = false
      ids.each do |id|
         if id < my_id
            exists_leader = true 
            break
         end
      end
      
      # If there is no leader, we will be the new leader
      if !exists_leader
         mcc.new_leader(my_id.to_s())
         puts "...#{MY_IP} will be leader"
         
         # Create your ssh key
         CloudSSH.generate_ssh_key()
      else
         puts "...Some other machine is/should be leader"
      end
      mcc.disconnect
      
      return
   end

end


# Starting function for nodes which do not belong to the cloud.
def not_cloud_start()
   
   # Try to find one virtual machine that is already running
   alive = false
   vm_leader = ""
   vm_ips.each do |vm|
      result = `#{PING} #{vm}`
      if $?.exitstatus == 0
         puts "#{vm} is up"
         alive = true
         vm_leader = vm
         break
      end
   end
   
   if !alive
      puts "All virtual machines are stopped"
      puts "Starting one of them..."
   
      # Start one of the virtual machines
      vm = vm_ips[rand(vm_ips.count)]     # Choose one randomly
      puts "Starting #{vm} ..."
      
      start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
      
      # That virtual machine will be the "leader" (actually the chosen one)
      vm_leader = vm
      
      # Copy important files to it
      #copy_cloud_files(vm_leader, "torque")
      
      puts "#{vm_leader} is being started"
      puts "Once started, do 'puppet apply manifest.pp' on #{vm_leader}" 
   else
      puts "#{vm_leader} is already running"
      puts "Do 'puppet apply manifest.pp' on #{vm_leader}"
   end

end


def leader_monitoring(ip_function, img_function)

   puts "#{MY_IP} is the leader"
   
   # Do monitoring
   deads = []
   vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(ip_function, img_function)
   vm_ips.each do |vm|
      puts "Monitoring #{vm}..."
      unless monitor_vm(vm, vm_ip_roles)
         deads << vm
      end
      puts "...Monitored"
   end
   
   # Check pool of physical machines
   pm_all_up, pm_up, pm_down = check_pool()
   
   if deads.count == 0
      puts "=========================="
      puts "== Cloud up and running =="
      puts "=========================="
   else
      # Raise again the dead machines
      deads.each do |vm|
         start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
      end
   end
            
end


################################################################################
# Auxiliar functions
################################################################################

# Starts a cloud formed by <vm_ips> performing <vm_ip_roles>.
def start_cloud(vm_ips, vm_ip_roles)

   puts "Starting the cloud"
   return torque_cloud_start(vm_ip_roles)

end
