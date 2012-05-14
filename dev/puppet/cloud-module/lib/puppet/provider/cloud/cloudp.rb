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
         vm_ips = []
         if resource[:type].to_s == "appscale"
            debug "[DBG] It is an appscale cloud"
            puts "It is an appscale cloud"
            vm_ips = appscale_yaml_parser(resource[:ip_file])
            debug "[DBG] File parsed"
            debug "[DBG] #{vm_ips}"
         elsif resource[:type].to_s == "web"
            debug "[DBG] It is a web cloud"
            puts "It is a web cloud"
            vm_ips, vm_ip_roles = web_yaml_ips(resource[:ip_file])
            vm_img_roles = web_yaml_images(resource[:img_file])
         elsif resource[:type].to_s == "jobs"
            debug "[DBG] It is a jobs cloud"
            puts "It is a jobs cloud"
            vm_ips = []
         else
            err "Cloud type undefined: #{resource[:type]}"
            err "Cloud type class: #{resource[:type].class}"
         end
         
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
                  alive[vm] = 0
               end
               
               vm_ips.each do |vm|
                  result = `ping -q -c 1 -w 4 #{vm}`
                  if $?.exitstatus == 0
                     debug "[DBG] #{vm} is up"
                     puts "#{vm} is up"
                     alive[vm] = 1
                  else
                     debug "[DBG] #{vm} is down"
                     puts "#{vm} is down"
                  end
               end
               
               # Monitor the alive machines. Start and configure the dead ones.
               vm_ips.each do |vm|
                  if alive[vm]
                     # If they are alive, monitor them
                     puts "Calling monitor for #{vm}"
                     monitor_vm(vm, vm_ip_roles, vm_img_roles)
                     puts "Monitor finished"
                     
                     # And we have finished
                     return
                  else
                     # If they are not alive, start and configure them
                     puts "Calling start for #{vm}"
                     start_vm(vm, vm_ip_roles, vm_img_roles, pm_up)
                  end
               end
               
               # Distribute important files to all machines
               vm_ips.each do |vm|
                  
                  # Cloud manifest
                  # FIXME : Check 'source' attribute in manifest
                  command = "scp /etc/puppet/manifests/init-cloud.pp" +
                            " root@#{vm}:/etc/puppet/manifests/init-cloud.pp"
                  result = `#{command}`
                  unless $?.exitstatus == 0
                     err "Impossible to copy init-cloud.pp to #{vm}"
                  end
                  
                  # Cloud description (YAML file)
                  command = "scp #{resource[:ip_file]} root@#{vm}:#{resource[:ip_file]}"
                  result = `#{command}`
                  unless $?.exitstatus == 0
                     err "Impossible to copy #{resource[:ip_file]} to #{vm}"
                  end
               end
               
               # Start the cloud
               puts "Starting the cloud"
               if resource[:type].to_s == "appscale"
                  if (resource[:app_email] == nil) || (resource[:app_password] == nil)
                     err "Need an AppScale user and password"
                     exit
                  else
                     puts "app_email = #{resource[:app_email]}"
                     puts "app_password = #{resource[:app_password]}"
                  end
                  debug "[DBG] Starting an appscale cloud"
                  puts  "Starting an appscale cloud"
                  
                  puppet_path = "/etc/puppet/"
                  appscale_manifest_path = puppet_path + "appscale_basic.pp"
                  appscale_manifest = File.open("/etc/puppet/modules/cloud/files/appscale-manifests/basic.pp", 'r').read()
                  puts "Creating manifest files on agent nodes"
                  mcollective_create_files(appscale_manifest_path, appscale_manifest)
                  puts "Manifest files created"
                  
                  # FIXME Only works if ssh keys are OK. Maybe Puppet source?
                  yaml_file = resource[:ip_file]
                  puts "Copying #{yaml_file} to 155.210.155.170:/tmp"
                  result = `scp #{yaml_file} root@155.210.155.170:/tmp`
                  ips_yaml = File.basename(resource[:ip_file])
                  ips_yaml = "/tmp/" + ips_yaml
                  puts "==Calling appscale_cloud_start"
                  ssh_user = "root"
                  ssh_host = "155.210.155.170"
                  appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                                       resource[:app_email], resource[:app_password],
                                       resource[:root_password])

               elsif resource[:type].to_s == "web"
                  debug "[DBG] Starting a web cloud"
                  puts  "Starting a web cloud"
                  
                  # Distribute ssh key to nodes to make login passwordless
                  key_path = "/root/.ssh/id_rsa.pub"
                  command_path = "/etc/puppet/modules/cloud/lib/puppet/provider/cloud"
                  password = resource[:root_password]
                  puts "Distributing ssh keys to nodes"
                  distribution.each do |pm, vms|
                     vms.each do |vm|
                        result = `#{command_path}/ssh_copy_id.sh root@#{vm} #{key_path} #{password}`
                        if $?.exitstatus == 0
                           puts "Copied ssh key to #{vm}"
                        else
                           err "Impossible to copy ssh key to #{vm}"
                        end
                     end
                  end
                  
                  # FIXME Only works if ssh keys are OK => Asks for password. Maybe Puppet source? 
                  yaml_file = resource[:ip_file]
                  puts "Copying #{yaml_file} to 155.210.155.170:/tmp"
                  result = `scp #{yaml_file} root@155.210.155.170:/tmp`
                  ips_yaml = File.basename(resource[:ip_file])
                  ips_yaml = "/tmp/" + ips_yaml
                  ssh_user = "root"
                  ssh_host = "155.210.155.170"
                  web_cloud_start(ssh_user, ssh_host, vm_ip_roles)

               elsif resource[:type].to_s == "jobs"
                  debug "[DBG] Starting a jobs cloud"
                  puts  "Starting a jobs cloud"
                  jobs_cloud_start

               else
                  debug "[DBG] Cloud type undefined: #{resource[:type]}"
                  err   "Cloud type undefined: #{resource[:type]}"
               end
               
               # Create file
               cloud_file = File.open("/tmp/cloud-#{resource[:name]}", 'w')
               cloud_file.puts(resource[:name])
               cloud_file.close
               
               
               puts "Cloud started"
               
               
               
            else     # We are not the leader or we have not received our ID yet
               puts "I am not the leader"
            
               if my_id != -1
                  # If we have received our ID, try to become leader
                  puts "Election leader algorithm"
               else
                  # If we have not received our ID, exit
                  return      # Using exit causes the following error:
                              # err: /Stage[main]//Cloud[mycloud]: \
                              # Could not evaluate: Puppet::Util::Log requires a message
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
         debug "[DBG] Cloud already started"
         
         # Check if you are the leader
         id = File.open("/tmp/cloud-id","r").read.chomp
         leader_id = File.open("tmp/cloud-leader","r").read.chomp
         
         if id == leader_id
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
         
         # Delete file
         File.delete("/tmp/cloud-#{resource[:name]}")
         
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
