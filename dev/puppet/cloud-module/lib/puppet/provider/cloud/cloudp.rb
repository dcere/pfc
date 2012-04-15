Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   # Commands needed to make the provider suitable
   #commands :grep => "/bin/grep"
   #commands :ip => "/sbin/ip"
   commands :ping => "/bin/ping"
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Some constants
   VIRSH_CONNECT = "virsh -c qemu:///system"

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
      #if !exists?
      if true

         # Check pool of physical machines
         pm_all_up, pm_up, pm_down = check_pool()
         if !pm_all_up
            debug "[DBG] Some physical machines are down"
            pm_down.each do |pm|
               debug "[DBG] - #{pm}"
            end
            puts "Some physical machines are down"
         end
         
         # Obtain the virtual machines' IPs
         vm_ips = []
         if resource[:type].to_s == "appscale"
            debug "[DBG] It is an appscale cloud"
            puts "It is an appscale cloud"
            vm_ips = appscale_yaml_parser(resource[:file])
            debug "[DBG] File parsed"
            debug "[DBG] #{vm_ips}"
         elsif resource[:type].to_s == "web"
            debug "[DBG] It is a web cloud"
            puts "It is a web cloud"
            vm_ips = web_yaml_parser(resource[:file])
         elsif resource[:type].to_s == "jobs"
            debug "[DBG] It is a jobs cloud"
            puts "It is a jobs cloud"
            vm_ips = []
         else
            debug "[DBG] Cloud type undefined: #{resource[:type]}"
            debug "[DBG] Cloud type class: #{resource[:type].class}"
            err "Cloud type undefined: #{resource[:type]}"
            err "Cloud type class: #{resource[:type].class}"
         end
         
         # Distribute virtual machines among physical machines
         instances = vm_ips.count
         vm_per_pm = instances / pm_up.length
         quantity = {}
         pm_up.each do |pm|
            if pm == pm_up[-1]
               quantity[pm] = vm_per_pm + instances % pm_up.length
               puts "#{pm} will host #{quantity[pm]} virtual machines"
            else
               quantity[pm] = vm_per_pm
               puts "#{pm} will host #{quantity[pm]} virtual machines"
            end
         end
         
         # Check if it is reasonable to host that many virtual machines
         quantity.each do |pm, vms|
            if vms > 3
               debug "[DBG] #{pm} is hosting more than 3 virtual machines"
               warning "#{pm} is hosting more than 3 virtual machines"
            end
         end
         
         # Prepare virtual machines
         distribution = {}
         pm_up.each do |pm|
            distribution[pm] = vm_ips.shift(quantity[pm])
         end
         debug "[DBG] Virtual machines distribution completed"
         puts "Virtual machines distribution completed"
         
         # Start virtual machines
         images = resource[:images]
         if images.count == 1
            # One image to rule them all
         elsif images.count == instances
            # N images to the N virtual machines in the kingdom of cloud
         else
            err "You gave me #{images.count} images and #{instances} instances"
            err "Either one image for all instances or as many as instances"
            exit
         end
         
         debug "[DBG] Creating domain files"
         puts "Creating domain files"
         
         # Create names and MAC addresses for all virtual machines
         mac_address = MAC_Address.new("52:54:01:00:00")
         mac_address_array = mac_address.generate_array(instances)
         vm_name = VM_Name.new("myvm")
         vm_name_array = vm_name.generate_array(instances)
         
         distribution.each do |pm, vms|
            
            # Get ERB template
            require 'erb'
            template = File.open(resource[:domain], 'r').read()
            erb = ERB.new(template)
            
            vms.each do |vm|
            
               # Create VM data
               vm_name = vm_name_array.shift
               vm_uuid = `uuidgen`
               vm_disk = resource[:images]
               vm_mac  = mac_address_array.shift
               myvm = VM.new(vm_name, vm_uuid, vm_disk, vm_mac)
               
               # Write vm domain file
               domain_file = File.open("/etc/puppet/modules/cloud/files/cloud-#{vm_name}.xml", 'w')
               debug "[DBG] Domain file created"
               domain_file.write(erb.result(myvm.get_binding))
               domain_file.close
               info "Domain file written"
               
               # Copy the domain definition file to the physical machine
               result = `scp /etc/puppet/modules/cloud/files/cloud-#{vm_name}.xml dceresuela@#{pm}:/tmp`
               if ($?.exitstatus == 0)
                  debug "[DBG] domain definition file copied"
               else
                  debug "[DBG] #{vm_name} impossible to copy domain definition file"
                  err   "#{vm_name} impossible to copy domain definition file"
               end
               
               ssh_connect = "ssh dceresuela@#{pm}"
               
               # Define the domain in the physical machine
               define_domain(ssh_connect, vm_name)
               
               # Start the domain
               start_domain(ssh_connect, vm_name)
               
            end      # vms.each
            
         end      # distribution.each
         
         # Check virtual machines are alive
         alive = {}
         distribution.each do |pm, vms|
            vms.each do |vm|
               alive[vm] = 0
            end
         end
         
         while alive.has_value?(0)     # FIXME Make it not so dramatic
            sleep(5)
            alive.keys.each do |vm|
               result = `ping -q -c 1 -w 4 #{vm}`
               if ($?.exitstatus == 0)
                  debug "[DBG] #{vm} is up"
                  alive[vm] = 1
               else
                  debug "[DBG] #{vm} is down"
               end
            end
         end
         
         # Start the cloud
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
            #mcollective_create_files("/tmp/test2","I am test2")
            puts "Manifest files created"
            
            # FIXME Only works if ssh keys are OK
            puts "Copying appscale-1-node.yaml to 155.210.155.170:/tmp"
            result = `scp /etc/puppet/modules/cloud/files/appscale-1-node.yaml root@155.210.155.170:/tmp`
            ips_yaml = File.basename(resource[:file])
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
            ips_yaml = File.basename(resource[:file])
            ips_yaml = "/tmp/" + ips_yaml
            ssh_user = "root"
            ssh_host = "155.210.155.170"
            web_cloud_start(ssh_user, ssh_host, ips_yaml, resource[:root_password])

         elsif resource[:type].to_s == "jobs"
            debug "[DBG] Starting a jobs cloud"
            puts  "Starting a jobs cloud"
            jobs_cloud_start

         else
            debug "[DBG] Cloud type undefined: #{resource[:type]}"
            err   "Cloud type undefined: #{resource[:type]}"
         end
         
         
         puts "Cloud started"
         
      else
         debug "[DBG] Cloud already started"
      end
      
   end


   # Makes sure the cloud is not running.
   def stop

      debug "[DBG] Stopping cloud %s" % [resource[:name]]

      if exists? && status == :running
         # Stop hosts
         virsh_connect = "virsh -c qemu:///system"
         images = resource[:images]
         images.each do |image|
            result = `#{virsh_connect} shutdown #{image}`
            if ($?.exitstatus == 0)
               debug "[DBG] #{image} was shut down"
            else
               debug "[DBG] #{image} impossible to shut down"
            end
         end
         
      end

   end


   def status
      return :stopped
   end


   # Ensure methods
   def create
      return true
   end
   

   def destroy
      return true
   end


   def exists?
      return false
   end
   

   #############################################################################
   # Auxiliar functions
   #############################################################################
   def check_pool
   
      all_up = true
      machines_up = []
      machines_down = []
      machines = resource[:pool]
      #debug "[DBG] Machines class: #{resource[:pool].class}"
      machines.each do |machine|
         result = `ping -q -c 1 -w 4 #{machine}`
         if ($?.exitstatus == 0)
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
   
   
   def define_domain(ssh_connect, vm_name)
   
      result = `#{ssh_connect} '#{VIRSH_CONNECT} define /tmp/mycloud-1.xml'`
      if ($?.exitstatus == 0)
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
      if ($?.exitstatus == 0)
         debug "[DBG] #{vm_name} started"
         return true
      else
         debug "[DBG] #{vm_name} impossible to start"
         err   "#{vm_name} impossible to start"
         return false
      end
   end
   
   
   def appscale_cloud_start(ssh_user, ssh_host, ips_yaml,
                            app_email=nil, app_password=nil, root_password=nil)
   
      require 'pty'
      require 'expect'
      
      # Sample dialog
      # -------------
      # Enter your desired administrator e-mail address: david@mail.com
      # 
      # The new administrator password must be at least six characters long and can include non-alphanumeric characters.
      # Enter your new password: 
      # Enter again to verify: 
      # Please wait for AppScale to prepare your machines for use.
      # Starting up XMPP server
      # 
      # Your user account has been created successfully.
      # 
      # Your user account has been created successfully.
      # No app uploaded. Use appscale-upload-app to upload an app later.
      # The status of your AppScale instance is at the following URL: http://155.210.155.73/status
      # Your XMPP username is david@155.210.155.73
      
      # Check arguments
      puts "appscale_cloud_start called with:"
      puts "  - app_email == #{app_email}"
      puts "  - app_password == #{app_password}"
      puts "  - root_password == #{root_password}"
      
      ssh_connect = "#{ssh_user}@#{ssh_host}"
      bin_path = "/usr/local/appscale-tools/bin"
      
      # Add key pairs
      debug "[DBG] About to add key pairs"
      puts "=About to add key pairs"
      debug "[DBG] ips.yaml file: #{ips_yaml}"
      arguments = "--auto --ips #{ips_yaml} --cp_pass #{root_password}"
      if Facter.value(:ipaddress) == ssh_host
         # Do it local
         result = `#{bin_path}/appscale-add-keypair #{arguments}`
      else
         # Do it remote
         result = `#{ssh_connect} '#{bin_path}/appscale-add-keypair #{arguments}'`
      end
      puts result
      if ($?.exitstatus == 0)
         debug "[DBG] Key pairs added"
         puts "Key pairs added"
      else
         debug "[DBG] Impossible to add key pairs"
         err   "Impossible to add key pairs"
      end
      
      # Run instances
      debug "[DBG] About to run instances"
      puts "=About to run instances"
      puts "This may take a while (~ 3 min), so please be patient"
      arguments = "--ips #{ips_yaml} --cp_user #{app_email} --cp_pass #{app_password}"
      if Facter.value(:ipaddress) == ssh_host
         # Do it local
         result = `#{bin_path}/appscale-run-instances #{arguments}`
      else
         # Do it remote
         result = `#{ssh_connect} '#{bin_path}/appscale-run-instances #{arguments}`
      end
      puts result
      if ($?.exitstatus == 0)
         debug "[DBG] Instances running"
         puts  "Instances running"
      else
         debug "[DBG] Impossible to run appscale instances"
         err   "Impossible to run appscale instances"
      end
      
   end
   
   
   def web_cloud_start(ssh_user, ssh_host, ips_yaml, root_password=nil)
   
      ssh_connect = "#{ssh_user}@#{ssh_host}"
      
   end
   
   
   def jobs_cloud_start
   end
   
   
end
