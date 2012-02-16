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
         
         # Wait for hosts to be running
         sleep(30)
         
         # Check hosts are alive
         ["192.168.1.101"].each do |server|
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
      return true
   end
   
   
end
