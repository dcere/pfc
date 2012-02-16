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

      if exists? && status != :running
         # Start hosts
      
         # Check hosts are alive
         ["localhost","useless"].each do |server|
            result = `ping -q -c 1 #{server}`
            if ($?.exitstatus == 0)
               debug "[DBG] #{server} is up"
            else
               debug "[DBG] #{server} is down"
            end
         end

      end

   end


   # Makes sure the cloud is not running.
   def stop

      debug "[DBG] Stopping cloud %s" % [resource[:name]]

      if exists? && status == :running
         # Stop cloud
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
      return true
   end
   
   
end
