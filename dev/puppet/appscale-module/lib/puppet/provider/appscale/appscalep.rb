Puppet::Type.type(:appscale).provide(:appscalep) do
   desc "Manages AppScale clouds formed by KVM virtual machines"

   # Require appscale auxiliar files
   require File.dirname(__FILE__) + '/appscale/appscale_yaml.rb'
   require File.dirname(__FILE__) + '/appscale/appscale_functions.rb'
   
   # Require generic files
   require '/etc/puppet/modules/generic-module/provider/mcollective_client.rb'
   Dir["/etc/puppet/modules/generic-module/provider/*.rb"].each { |file| require file }
   
   # Commands needed to make the provider suitable
   commands :ping => "/bin/ping"
   commands :grep => "/bin/grep"
   commands :ps   => "/bin/ps"
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Some constants
   VIRSH_CONNECT = "virsh -c qemu:///system"
   MY_IP = Facter.value(:ipaddress)
   PING = "ping -q -c 1 -w 4"

   LAST_MAC_FILE = "/tmp/cloud-last-mac"
   LAST_ID_FILE  = "/tmp/cloud-last-id"
   
   DOMAINS_FILE = "/tmp/defined-domains" # resource[:name] cannot be used at this point
   
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
         #vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(method(:appscale_yaml_ips),
         #                                                   method(:appscale_yaml_images))
         vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data()
         
         # Check whether you are one of the virtual machines
         puts "Checking whether this machine is part of the cloud..."
         part_of_cloud = vm_ips.include?(MY_IP)
         if part_of_cloud
            puts "#{MY_IP} is part of the cloud"
            
            # Check if you are the leader
            puts "Checking whether we are the leader..."
            my_id = CloudLeader.get_id()
            leader = CloudLeader.get_leader()
 
            if my_id == leader && my_id != -1
               leader_start("appscale", vm_ips, vm_ip_roles, vm_img_roles, pm_up,
                            method(:appscale_monitor))
            else
               common_start(my_id)
            end
         else
            puts "#{MY_IP} is not part of the cloud"
            not_cloud_start("appscale", vm_ips, vm_ip_roles, vm_img_roles, pm_up)
         end
         
      else
         
         # Cloud exists => Monitoring operations
         puts "Cloud already started"
         
         # Get your ID
         my_id = CloudLeader.get_id()
         if my_id == -1
            err "ID file does not exist"
         end
         
         # Get leader's ID
         leader = CloudLeader.get_leader()
         if leader == -1
            err "LEADER file does not exist"
         end

         # Check if you are the leader
         if my_id == leader && my_id != -1
            leader_monitoring(method(:appscale_monitor))
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
         
         puts "It is an appscale cloud"
         
         # Stop cloud infrastructure
         appscale_cloud_stop(MY_IP)    # TODO What if we run stop on a different machine than start?
         
         # Get pool of physical machines
         pms = resource[:pool]
         
         # Shutdown and undefine all virtual machines explicitly created for this cloud
         shutdown_pms(pms)
         
         # Stop cron jobs on all machines
         puts "Stopping cron jobs on all machines..."
         mcc = MCollectiveCronClient.new("cronos")
         string = "init-appscale"
         mcc.delete_line(CRON_FILE, string)
         # WARNING: Do not disconnect the mcc or you will get a 'Broken pipe' error
         
         # Delete files
         delete_files()
         
         # Note: As all the files deleted so far are located in the /tmp directory
         # only the machines that are still alive need to delete these files.
         # If the machine was shut down, these files will not be there the next
         # time it is started, so there is no need to delete them.
         
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
   
   def pm_user
   end
   
   def starting_mac_address
   end
   
   def root_password
   end
   
   def app_email
   end
   
   def app_password
   end
   
   
end
