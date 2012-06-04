Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   # Require appscale auxiliar files
   require File.dirname(__FILE__) + '/appscale/appscale_yaml.rb'
   require File.dirname(__FILE__) + '/appscale/appscale_functions.rb'

   # Require web auxiliar files
   require File.dirname(__FILE__) + '/web/web_yaml.rb'
   require File.dirname(__FILE__) + '/web/web_functions.rb'
   
   # Require jobs auxiliar files
   require File.dirname(__FILE__) + '/jobs/jobs_yaml.rb'
   require File.dirname(__FILE__) + '/jobs/jobs_functions.rb'
   
   # Require MCollective files
   require File.dirname(__FILE__) + '/mcollective/mcollective_client.rb'
   require File.dirname(__FILE__) + '/mcollective/mcollective_files.rb'
   require File.dirname(__FILE__) + '/mcollective/mcollective_leader.rb'
   require File.dirname(__FILE__) + '/mcollective/mcollective_cron.rb'
   
   # Require monitoring files
   require File.dirname(__FILE__) + '/monitor/cloudmonitor.rb'
   
   # Require ssh files
   require File.dirname(__FILE__) + '/ssh/cloudssh.rb'
   
#   Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file| 
#      require File.basename(file, File.extname(file))
#   end

   # Commands needed to make the provider suitable
   commands :ping => "/bin/ping"
   #commands :grep => "/bin/grep"
   #commands :ps   => "/bin/ps"
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Some constants
   VIRSH_CONNECT = "virsh -c qemu:///system"
   MY_IP = Facter.value(:ipaddress)
   PING = "ping -q -c 1 -w 4"

   ID_FILE     = "/tmp/cloud-id"
   LEADER_FILE = "/tmp/cloud-leader"

   LAST_MAC_FILE = "/tmp/cloud-last-mac"
   LAST_ID_FILE  = "/tmp/cloud-last-id"
   
   DOMAINS_FILE = "/tmp/defined-domains" # resource[:name] cannot be used at this point
   
#   TIME = 20      # Start up time for a virtual machine     # TODO Check if it is needed
   
   CRON_FILE = "/var/spool/cron/crontabs/root"

   # Makes sure the cloud is running.
   def start

      puts "Starting cloud %s" % [resource[:name]]
      
      # Check existence
      if !exists?
         # Cloud does not exist => Startup operations
         
         # Check pool of physical machines
         puts "Checking pool of physical machines..."
         pm_all_up, pm_up, pm_down = check_pool()
         if !pm_all_up
            puts "Some physical machines are down"
            pm_down.each do |pm|
               debug "[DBG] - #{pm}"
            end
         end
         
         # Obtain the virtual machines' IPs
         puts "Obtaining the virtual machines' IPs..."
         vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data()
         
         # Check whether you are one of the virtual machines
         puts "Checking whether we are one of the virtual machines..."
         part_of_cloud = vm_ips.include?(MY_IP)
         if part_of_cloud
            puts "#{MY_IP} is part of the cloud"
            
            # Check if you are the leader
            puts "Checking whether we are the leader..."
            le = LeaderElection.new()
            my_id = le.get_id()
            leader = le.get_leader()
 
            if my_id != -1 && my_id == leader
            
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
               
               #################################################################
               # Test area
               #################################################################
#               out, success = CloudSSH.execute_remote("god -c /unassg/asdugk", "155.210.155.178")
#               if success
#                  puts "Remote command executed"
#               else
#                  puts "Remote command not executed"
#               end
#               return
               
               
               
               # Wait for all machines to be started
               unless deads
               
                  # If not already started, start the cloud
                  unless File.exists?("/tmp/cloud-#{resource[:name]}")
                     
                     # Check expect is installed
                     # TODO
                     
                     # Copy important files to all machines
                     puts "Copying important files to all virtual machines"
                     copy_cloud_files(vm_ips)      # TODO Move it to monitor and call it each time for one vm?
                  
                     # Start the cloud
                     if start_cloud(vm_ips, vm_ip_roles)
                        
                        # Make cloud nodes manage themselves
                        #auto_manage()     # Only if cloud was started properly FIXME Uncomment after tests
                        
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
               
               
               
            else
               
               # We are not the leader or we have not received our ID yet
               puts "#{MY_IP} is not the leader"
            
               if my_id == -1
                  
                  # If we have not received our ID, let's assume we will be the leader
                  id_file = File.open(ID_FILE, 'w')
                  id_file.puts("0")
                  id_file.close
                  leader_file = File.open(LEADER_FILE, 'w')
                  leader_file.puts("0")
                  leader_file.close
                  
                  puts "#{MY_IP} will be the leader"
                  
                  # Create your ssh key
                  CloudSSH.generate_ssh_key()
                  
               else
                  
                  # If we have received our ID, try to become leader
                  puts "Trying to become leader..."
                  
                  # Get your ID
                  le = LeaderElection.new()
                  my_id = le.get_id()
                  
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
                     mcc.new_leader(my_id)
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
            
         else
            
            # We are not part of the cloud
            puts "#{MY_IP} is not part of the cloud"
            
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
               #copy_cloud_files(vm_leader)
               
               puts "#{vm_leader} is being started"
               puts "Once started, do 'puppet apply manifest.pp' on #{vm_leader}" 
            else
               puts "#{vm_leader} is already running"
               puts "Do 'puppet apply manifest.pp' on #{vm_leader}"
            end 
            
         end
         
         
         
      else
         
         # Cloud exists => Management operations
         puts "Cloud already started"
         
         # Get your ID
         id_file = File.open(ID_FILE,'r')
         if id_file
            id = id_file.read().chomp()
            id_file.close
         else
            err "File #{ID_FILE} does not exist"
         end
         
         # Get leader's ID
         leader_file = File.open(LEADER_FILE,'r')
         if leader_file
            leader = leader_file.read().chomp()
            leader_file.close
         else
            err "File #{LEADER_FILE} does not exist"
         end

         # Check if you are the leader
         if id == leader
            puts "#{MY_IP} is the leader"
            
            # Do monitoring
            deads = []
            vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data()
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
            
         else
            puts "#{MY_IP} is not the leader"      # Nothing to do
         end
      end
      
   end


   # Makes sure the cloud is not running.
   def stop

      puts "Stopping cloud %s" % [resource[:name]]

      if !exists?
         err "Cloud does not exist"
         return
      end
      if status != :running
         err "Cloud is not running"
         return
      end
      if exists? && status == :running
         
         # Stop cloud infrastructure
         if resource[:type] == "appscale"
            puts "It is an appscale cloud"
            appscale_cloud_stop(MY_IP)    # TODO What if we run stop on a different machine than start?
         elsif resource[:type] == "web"
            puts "It is a web cloud"
         elsif resource[:type] == "jobs"
            puts "It is a jobs cloud"
         else
            err "Cloud type undefined: #{resource[:type]}"
            err "Cloud type class: #{resource[:type].class}"
            return
         end
         
         
         # Get pool of physical machines
         pms = resource[:pool]
         
         # Shutdown and undefine all virtual machines explicitly created for this cloud
         pms.each do |pm|
         
            ssh_connect = "ssh dceresuela@#{pm}"
            
            # Bring the defined domains file from the physical machine to this one
            result = `scp dceresuela@#{pm}:#{DOMAINS_FILE} #{DOMAINS_FILE}`
            if $?.exitstatus == 0
            
               puts "#{DOMAINS_FILE} exists in #{pm}"
               
               # Open files
               defined_domains = File.open(DOMAINS_FILE, 'r')
            
               # Stop nodes
               defined_domains.each_line do |domain|
                  domain.chomp!
                  result = `#{ssh_connect} '#{VIRSH_CONNECT} shutdown #{domain}'`
                  if $?.exitstatus == 0
                     debug "[DBG] #{domain} was shutdown"
                  else
                     debug "[DBG] #{domain} impossible to shutdown"
                     err "#{domain} impossible to shutdown"
                  end
               end
               
               # Undefine local domains
               defined_domains.rewind
               defined_domains.each_line do |domain|
                  domain.chomp!
                  result = `#{ssh_connect} '#{VIRSH_CONNECT} undefine #{domain}'`
                  if $?.exitstatus == 0
                     debug "[DBG] #{domain} was undefined"
                  else
                     debug "[DBG] #{domain} impossible to undefine"
                     err "#{domain} impossible to undefine"
                  end
               end
               
               # Delete the defined domains file on the physical machine
               result = `#{ssh_connect} 'rm -rf #{DOMAINS_FILE}'`
            
            else
               # Some physical machines might not have any virtual machine defined.
               # For instance, if they were already defined and running when we
               # started the cloud.
               puts "No #{DOMAINS_FILE} file found in #{pm}"
            end
            
         end   # pms.each
         
         # Stop cron jobs on all machines
         puts "Stopping cron jobs on all machines..."
         mcc = MCollectiveCronClient.new("cronos")
         string = "init-#{resource[:type]}"
         mcc.delete_line(CRON_FILE, string)
         # WARNING: Do not disconnect the mcc or you will get a 'Broken pipe' error
         
         # Delete files
         puts "Deleting cloud files on all machines..."
         
         # Create an MCollective client so that we avoid errors that appear
         # when you create more than one client in a short time
         mcc = MCollectiveFilesClient.new("files")
         
         # Delete leader, id, last_id and last_mac files on all machines (leader included)
         mcc.delete_file(LEADER_FILE)                          # Leader ID
         mcc.delete_file(ID_FILE)                              # ID
         mcc.delete_file(LAST_ID_FILE)                         # Last ID
         mcc.delete_file(LAST_MAC_FILE)                        # Last MAC address
         mcc.disconnect       # Now it can be disconnected
         
         # Delete rest of regular files on leader machine
         files = [DOMAINS_FILE,                                # Domains file
                  "/tmp/cloud-#{resource[:name]}"]             # Cloud file
         files.each do |file|
            if File.exists?(file)
               File.delete(file)
            else
               puts "File #{file} does not exist"
            end
         end            
         
         # Note: As they are included in the /tmp directory, only the machines
         # that are still alive need to delete these files. If the machine was
         # shut down, these files will not be the next time it is started.
         
         puts "==================="
         puts "== Cloud stopped =="
         puts "==================="
         
      end
   
   end


   def status
      if File.exists?("/tmp/cloud-#{resource[:name]}")
         return :running
      else
         return :stopped
      end
   end


   # Ensure methods
   def create
      return true
   end
   

   def destroy
      return true
   end


   def exists?
      return File.exists?("/tmp/cloud-#{resource[:name]}")
   end
   
   
   #############################################################################
   # Properties need methods
   #############################################################################
   def pool
   end
   
   def app_email
   end
   
   def app_password
   end
   
   def root_password
   end
   
   
end
