Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   # Commands needed to make the provider suitable
   commands :virtinstall => "/usr/bin/virt-install"
   commands :virsh => "/usr/bin/virsh"
   #commands :grep => "/bin/grep"
   #commands :ip => "/sbin/ip"
   commands :ping => "/bin/ping"

   # Operating system restrictions
   confine :osfamily => "Debian"


   # Makes sure the cloud is running.
   def start

      debug "[DBG] Starting cloud %s" % [resource[:name]]
      puts "Starting cloud %s" % [resource[:name]]
      
      # Check existence
      if !exists?

         # Check pool of physical machines
         pm_all_up, pm_up, pm_down = check_pool()
         if !pm_all_up
            debug "[DBG] Some physical machines are down"
            pm_down.each do |pm|
               debug "[DBG] - #{pm}"
            end
            puts "Some physical machines are down"
         end
         
         # Distribute virtual machines among physical machines
         instances = resource[:instances].to_i
         vm_per_pm = instances / pm_up.length
         distribution = {}
         pm_up.each do |pm|
            if pm == pm_up[-1]
               distribution[pm] = vm_per_pm + instances % pm_up.length
               puts "#{pm} hosts #{distribution[pm]} virtual machines"
            else
               distribution[pm] = vm_per_pm
               puts "#{pm} hosts #{distribution[pm]} virtual machines"
            end
         end
         
         # Check if it is reasonable to host that many virtual machines
         # ...
         
         # Start hosts
         virsh_connect = "virsh -c qemu:///system"
         images = resource[:images]
         images.each do |image|
            result = `#{virsh_connect} start #{image}`
            if ($?.exitstatus == 0)
               debug "[DBG] #{image} started"
            else
               debug "[DBG] #{image} impossible to start"
            end
         end
         
         # Check hosts are alive
         alive = {"127.0.0.1" => 0, "192.168.1.101" => 0}
         while alive.has_value?(0)
            sleep(5)
            alive.keys.each do |server|
               result = `ping -q -c 1 #{server}`
               if ($?.exitstatus == 0)
                  debug "[DBG] #{server} is up"
                  alive[server] = 1
               else
                  debug "[DBG] #{server} is down"
               end
            end
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
      machines.each do |machine|
         result = `ping -q -c 1 #{machine}`
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
   
   
   
   
   
   
end
