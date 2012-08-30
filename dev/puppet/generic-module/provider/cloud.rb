class Cloud

   attr_reader :resource

   def initialize(infrastructure, leader, resource, error_function)

      @vm_manager = CloudVM.new(infrastructure, leader, resource, error_function)
      @leader     = leader
      @resource   = resource
      @err        = error_function

   end

   #############################################################################
   # Start cloud functions
   #############################################################################

   # Starting function for leader node.
   def leader_start(cloud_type, vm_ips, vm_ip_roles, vm_img_roles, pm_up,
                    monitor_function)
      
      # We are the leader
      puts "#{MY_IP} is the leader"
      
      # Check wether virtual machines are alive or not
      puts "Checking whether virtual machines are alive..."
      alive = {}
      vm_ips.each do |vm|
         if alive?(vm)
            alive[vm] = true
         else
            alive[vm] = false
            puts "#{vm} is down"
         end
      end
      
      # Monitor the alive machines. Start and configure the dead ones.
      deads = false
      vm_ips.each do |vm|
         if alive[vm]
            # If they are alive, monitor them
            puts "Monitoring #{vm}..."
            @vm_manager.monitor_vm(vm, vm_ip_roles, monitor_function)
            puts "...Monitored"
         else
            # If they are not alive, start and configure them
            puts "Starting #{vm}..."
            @vm_manager.start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
            puts "...Started"
            deads = true
         end
      end
      
      # Wait for all machines to be started
      unless deads
      
         # If not already started, start the cloud
         unless File.exists?("/tmp/cloud-#{@resource[:name]}")
            
            # Copy important files to all machines
            puts "Copying important files to all virtual machines"
            copy_cloud_files(vm_ips, cloud_type)
         
            # Start the cloud
            if start_cloud(@resource, vm_ips, vm_ip_roles)
               
               # Make cloud nodes manage themselves
               auto_manage(cloud_type)     # Only if cloud was started properly
               
               # Create file
               cloud_file = File.open("/tmp/cloud-#{@resource[:name]}", 'w')
               cloud_file.puts(@resource[:name])
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
   def common_start()

      # We are not the leader or we have not received our ID yet
      puts "#{MY_IP} is not the leader"
            
      if @leader.id == -1
         
         # If we have not received our ID, let's assume we will be the leader
         @leader.set_id(0)
         @leader.set_leader(0)
         
         puts "#{MY_IP} will be the leader"
         
         # Create your ssh key
         CloudSSH.generate_ssh_key()
         
      else
         
         # If we have received our ID, try to become leader
         puts "Trying to become leader..."
         
         # Get all machines' IDs
         mcc = MCollectiveLeaderClient.new("leader")
         ids = mcc.ask_id()
         
         # See if some other machine is leader
         exists_leader = false
         ids.each do |id|
            if id < @leader.id
               exists_leader = true 
               break
            end
         end
         
         # If there is no leader, we will be the new leader
         if !exists_leader
            mcc.new_leader(@leader.id.to_s())
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
   def not_cloud_start(cloud_type, vm_ips, vm_ip_roles, vm_img_roles, pm_up)
      
      # Try to find one virtual machine that is already running
      vm_ips.each do |vm|
         if alive?(vm)
            # This machine is running
            puts "#{vm} is up"
            vm_leader = vm

            # Inform the user of this machine
            puts "#{vm_leader} is already running"
            puts "Do 'puppet apply manifest.pp' on #{vm_leader}"
            return
         end
      end
      
      # No machines are running
      puts "All virtual machines are stopped"
      puts "Starting one of them..."
   
      # Start one of the virtual machines
      vm = vm_ips[rand(vm_ips.count)]     # Choose one randomly
      puts "Starting #{vm} ..."
      
      @vm_manager.start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
      
      # That virtual machine will be the "leader" (actually the chosen one)
      vm_leader = vm
      
      # Copy important files to it
      #copy_cloud_files(vm_leader, cloud_type)
      
      puts "#{vm_leader} is being started"
      puts "Once started, do 'puppet apply manifest.pp' on #{vm_leader}"

   end


   # Monitoring function for leader node.
   def leader_monitoring(monitor_function)

      puts "#{MY_IP} is the leader"
      
      # Do monitoring
      deads = []
      vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(@resource)
      vm_ips.each do |vm|
         puts "Monitoring #{vm}..."
         unless @vm_manager.monitor_vm(vm, vm_ip_roles, monitor_function)
            deads << vm
         end
         puts "...Monitored"
      end
      
      # Check pool of physical machines
      pm_up, pm_down = check_pool()
      
      if deads.count == 0
         puts "=========================="
         puts "== Cloud up and running =="
         puts "=========================="
      else
         # Raise again the dead machines
         deads.each do |vm|
            @vm_manager.start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
         end
      end
               
   end


   #############################################################################
   # Stop cloud functions
   #############################################################################

   # Stoping function for leader node.
   def leader_stop(cloud_type, stop_function)

      # Stop cron jobs on all machines
      stop_cron_jobs(cloud_type)
      
      # Stop the cloud with the provided method
      vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(@resource)
      stop_function.call(@resource, vm_ip_roles)
      
      # Shutdown and undefine all virtual machines explicitly created for
      # this cloud
      @vm_manager.shutdown_vms()
      
      # Delete cloud related files
      delete_files()
      
      # Note: As all the files deleted so far are located in the /tmp directory
      # only the machines that are still alive need to delete these files.
      # If the machine was shut down, these files will not be there the next
      # time it is started, so there is no need to delete them.
      
      puts "==================="
      puts "== Cloud stopped =="
      puts "==================="

   end

   ## Shuts down virtual machines
   def shutdown_vms()
      @vm_manager.shutdown_vms()
   end


   # Stops cron jobs on all machines.
   def stop_cron_jobs(cloud_type)

      mcc = MCollectiveCronClient.new("cronos")
      string = "init-#{cloud_type}"
      mcc.delete_line(CloudCron::CRON_FILE, string)

   end


   # Deletes cloud files on all machines.
   def delete_files()

      puts "Deleting cloud files on all machines..."
      
      # Create an MCollective client so that we avoid errors that appear
      # when you create more than one client in a short time
      mcc = MCollectiveFilesClient.new("files")
      
      # Delete leader, id, last_id and last_mac files on all machines
      # (leader included)
      mcc.delete_file(CloudLeader::LEADER_FILE)             # Leader ID
      mcc.delete_file(CloudLeader::ID_FILE)                 # ID
      mcc.delete_file(CloudLeader::LAST_ID_FILE)            # Last ID
      mcc.delete_file(CloudVM::LAST_MAC_FILE)               # Last MAC address
      mcc.disconnect       # Now it can be disconnected
      
      # Delete rest of regular files on leader machine
      files = [CloudInfrastructure::DOMAINS_FILE,           # Domains file
               "/tmp/cloud-#{@resource[:name]}"]            # Cloud file
      files.each do |file|
         if File.exists?(file)
            File.delete(file)
         else
            puts "File #{file} does not exist"
         end
      end

   end


   #############################################################################
   # Auxiliar functions
   #############################################################################

   # Checks the pool of physical machines are OK.
   def check_pool()

      machines_up = []
      machines_down = []
      machines = @resource[:pool]
      machines.each do |machine|
         if alive?(machine)
            machines_up << machine
         else
            machines_down << machine
         end
      end
      return machines_up, machines_down
      
   end


   # Checks if this node is the leader
   def leader?()
    
      return @leader.leader?

   end


   # Copies important files to all machines inside <ips>.
   def copy_cloud_files(ips, cloud_type)
   # Use MCollective?
   #  - Without MCollective we are able to send it to both one machine or multiple
   #    machines without changing anything, so not really.

      ips.each do |vm|
      
         if vm != MY_IP
            
            # Cloud manifest
            file = "init-#{cloud_type}.pp"
            path = "/etc/puppet/modules/#{cloud_type}/manifests/#{file}"
            out, success = CloudSSH.copy_remote(path, vm, path)
            unless success
               @err.call "Impossible to copy #{file} to #{vm}"
            end

         end
         
      end
      
   end


   # Makes the cloud auto-manageable through crontab files.
   def auto_manage(cloud_type)

      cron_file = "crontab-#{cloud_type}"
      path = "/etc/puppet/modules/#{cloud_type}/files/cron/#{cron_file}"
      
      if File.exists?(path)
         file = File.open(path, 'r')
         line = file.read().chomp()
         file.close
         
         # Add the 'puppet apply manifest.pp' line to the crontab file
         mcc = MCollectiveCronClient.new("cronos")
         mcc.add_line(CloudCron::CRON_FILE, line)
         mcc.disconnect
      else
         @err.call "Impossible to find cron file at #{path}"
      end
      
   end


   #############################################################################
   # Helper functions
   #############################################################################


   # Checks if a machine is alive.
   def alive?(ip)

      ping = "ping -q -c 1 -w 4"
      result = `#{ping} #{ip}`
      return $?.exitstatus == 0

   end


end
