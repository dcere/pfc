Puppet::Type.type(:torque).provide(:torquep) do
   desc "Manages Torque clouds formed by KVM virtual machines"

   # Require torque auxiliar files
   require File.dirname(__FILE__) + '/torque/torque_yaml.rb'
   require File.dirname(__FILE__) + '/torque/torque_functions.rb'
   require File.dirname(__FILE__) + '/torque/torque_parsing.rb'
   
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
   #   They are in the generic cloud files

   # Makes sure the cloud is running.
   def start

      cloud = Cloud.new(CloudInfrastructure.new(), CloudLeader.new(), resource,
                        method(:err))
      puts "Starting cloud %s" % [resource[:name]]
      
      # Check existence
      if !exists?
         # Cloud does not exist => Startup operations
         
         # Check pool of physical machines
         puts "Checking pool of physical machines..."
         pm_up, pm_down = cloud.check_pool()
         unless pm_down.empty?
            puts "Some physical machines are down"
            pm_down.each do |pm|
               puts " - #{pm}"
            end
         end
         
         # Obtain the virtual machines' IPs
         puts "Obtaining the virtual machines' IPs..."
         #vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(method(:torque_yaml_ips),
         #                                                   method(:torque_yaml_images))
         vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data()
         
         
         # Check whether you are one of the virtual machines
         puts "Checking whether this machine is part of the cloud..."
         part_of_cloud = vm_ips.include?(MY_IP)
         if part_of_cloud
            puts "#{MY_IP} is part of the cloud"
            
            # Check if you are the leader
            if cloud.leader?()
               cloud.leader_start("torque", vm_ips, vm_ip_roles, vm_img_roles,
                                  pm_up, method(:torque_monitor))
            else
               cloud.common_start()
            end
         else
            puts "#{MY_IP} is not part of the cloud"
            cloud.not_cloud_start("torque", vm_ips, vm_ip_roles, vm_img_roles,
                                  pm_up)
         end
         
      else
         
         # Cloud exists => Monitoring operations
         puts "Cloud already started"

         # Check if you are the leader
         if cloud.leader?()
            cloud.leader_monitoring(method(:torque_monitor))
         else
            puts "#{MY_IP} is not the leader"      # Nothing to do
         end
      end
      
   end


   # Makes sure the cloud is not running.
   def stop

      cloud = Cloud.new(CloudInfrastructure.new(), CloudLeader.new(), resource,
                        method(:err))
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
         
         puts "It is a torque cloud"
         
         # Stop cloud infrastructure
         #vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data(method(:torque_yaml_ips),
         #                                                   method(:torque_yaml_images))
         vm_ips, vm_ip_roles, vm_img_roles = obtain_vm_data()
         torque_cloud_stop(vm_ip_roles)
         
         # Shutdown and undefine all virtual machines explicitly created for this cloud
         cloud.shutdown_vms()
         
         # Stop cron jobs on all machines
         cloud.stop_cron_jobs("torque")      # TODO Check order
         
         # Delete files
         cloud.delete_files()
         
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
   #def create
   #   return true
   #end
   

   #def destroy
   #   return true
   #end


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
   
   def head
   end
   
   def compute
   end
   
end
