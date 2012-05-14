Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   # Require appscale auxiliar files
   require File.dirname(__FILE__) + '/appscale/appscale_yaml.rb'
   require File.dirname(__FILE__) + '/appscale/appscale_functions.rb'

   # Require web auxiliar files
   require File.dirname(__FILE__) + '/web/web_yaml.rb'
   require File.dirname(__FILE__) + '/web/web_functions.rb'
#   Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file| 
#      require File.basename(file, File.extname(file))
#   end

   # Commands needed to make the provider suitable
   #commands :grep => "/bin/grep"
   #commands :ip => "/sbin/ip"
   commands :ping => "/bin/ping"
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Some constants
   VIRSH_CONNECT = "virsh -c qemu:///system"
   MY_IP = Facter.value(:ipaddress)


   # Virtual machine class
   class VM
      attr_accessor :vm
      
      def initialize(name,uuid,disk,mac)
      @vm = {
         :name => "#{name}",
         :uuid => "#{uuid}",
         :disk => "#{disk}",
         :mac  => "#{mac}"}
      end
      
      def get_binding
         binding()
      end
   end



   # Makes sure the cloud is running.
   def start

      debug "[DBG] Starting cloud %s" % [resource[:name]]
      puts "Starting cloud %s" % [resource[:name]]
      
      # Check existence
      if !exists?
         # Cloud does not exist => Startup operations
         
         # Check pool of physical machines
         puts "Checking pool of physical machines..."
         pm_all_up, pm_up, pm_down = check_pool()
         if !pm_all_up
            debug "[DBG] Some physical machines are down"
            pm_down.each do |pm|
               debug "[DBG] - #{pm}"
            end
            puts "Some physical machines are down"
         end
         
         # Obtain the virtual machines' IPs
         puts "Obtaining the virtual machines' IPs..."
         vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_ips()
         
         # Check whether you are one of the virtual machines
         puts "Checking whether we are one of the virtual machines..."
         part_of_cloud = vm_ips.include?(MY_IP)
         if part_of_cloud
            puts "I am one of the virtual machines"
            
            # Check if you are the leader
            puts "Checking whether we are the leader..."
            le = LeaderElection.new("/tmp/cloud-id", "/tmp/cloud-leader")
            my_id = le.get_id
            leader_id = le.get_leader_id
 
            if my_id != -1 && my_id == leader_id      # We are the leader
               puts "I am the leader"
               
               # Check virtual machines are alive
               alive = {}
               vm_ips.each do |vm|
                  alive[vm] = false
               end
               
               vm_ips.each do |vm|
                  result = `ping -q -c 1 -w 4 #{vm}`
                  if $?.exitstatus == 0
                     debug "[DBG] #{vm} is up"
                     puts "#{vm} is up"
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
                     monitor_vm(vm, vm_ip_roles, vm_img_roles)
                     puts "...Monitored"
                  else
                     # If they are not alive, start and configure them
                     puts "Starting #{vm}..."
                     start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
                     puts "...Started"
                     deads = true
                  end
               end
               
               # If there were dead machines, give them some time to raise
               puts "Some machines are starting. I will continue in 20 seconds"
               if deads
                  sleep(20)
               end
               
               # Distribute important files to all machines
               puts "Distributing important files to all virtual machines"
               copy_cloud_files(vm_ips)
               
               # If not already started, start the cloud
               unless File.exists?("/tmp/cloud-#{resource[:name]}")
                  # Start the cloud
                  start_cloud(vm_ips, vm_ip_roles)
                  
                  # Create file
                  cloud_file = File.open("/tmp/cloud-#{resource[:name]}", 'w')
                  cloud_file.puts(resource[:name])
                  cloud_file.close
               end
               
               puts "Cloud started"
               
               
            else     # We are not the leader or we have not received our ID yet
               puts "I am not the leader"
            
               if my_id == -1
                  # If we have not received our ID, let's assume we will be the leader
                  puts "Election leader algorithm"
                  
                  # If no one answers, we are the leader
                  id_file = File.open("/tmp/cloud-id", 'w')
                  id_file.puts("0")
                  id_file.close
                  leader_file = File.open("/tmp/cloud-leader", 'w')
                  leader_file.puts("0")
                  leader_file.close
                  
                  puts "I will be the leader"
                  
               else
                  # If we have received our ID, try to become leader
                  return
               end
            end
            
         else
            puts "I am not one of the virtual machines"
            # Start one of the virtual machines
            
            # Copy important files to it
            
            # Make it leader
         end
         
         
         
      else
         # Cloud exists => Management operations
         puts "Cloud already started"
         
         # Get your ID
         id_file = File.open("/tmp/cloud-id",'r')
         if id_file
            id = id_file.read().chomp()
            id_file.close
         else
            err "File /tmp/cloud-id does not exist"
         end
         
         # Get leader's ID
         leader_file = File.open("/tmp/cloud-leader",'r')
         if leader_file
            leader = leader_file.read().chomp()
            leader_file.close
         else
            err "File /tmp/cloud-leader does not exist"
         end

         # Check if you are the leader
         if id == leader
            puts "I am the leader"
         else
            puts "I am not the leader"
         end
      end
      
   end


   # Makes sure the cloud is not running.
   def stop

      debug "[DBG] Stopping cloud %s" % [resource[:name]]

      if !exists?
         err "Cloud does not exist"
         return
      end
      if status != :running
         err "Cloud is not running"
         return
      end
      if exists? && status == :running
         
         pms = resource[:pool]
         
         pms.each do |pm|
         
            ssh_connect = "ssh dceresuela@#{pm}"
            defined_domains_path = "/tmp/defined-domains-#{resource[:name]}"
            
            result = `scp dceresuela@#{pm}:#{defined_domains_path} #{defined_domains_path}`
            if $?.exitstatus == 0
            
               puts "#{defined_domains_path} exists in #{pm}"
               
               # Open files
               defined_domains = File.open(defined_domains_path)
            
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
               result = `#{ssh_connect} 'rm -rf /tmp/defined-domains-#{resource[:name]}'`
            
            else
               err "No #{defined_domains_path} file found in #{pm}"
            end
            
         end   # pms.each
         
         # Delete files
         File.delete("/tmp/defined-domains-#{resource[:name]}")      # Domains file
         File.delete("/tmp/cloud-#{resource[:name]}")                # Cloud file
         
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
   def images
   end
   
   def pool
   end
   
   def app_email
   end
   
   def app_password
   end
   
   def root_password
   end
   
   
   #############################################################################   
   def jobs_cloud_start
   end
   
   
end
