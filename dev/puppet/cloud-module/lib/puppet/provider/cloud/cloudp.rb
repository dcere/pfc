Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   commands :virtinstall => "/usr/bin/virt-install"
   commands :virsh => "/usr/bin/virsh"
   commands :grep => "/bin/grep"
   commands :ip => "/sbin/ip"


   # Makes sure the cloud is running.
   def start

      debug "Starting cloud %s" % [resource[:name]]

      if exists? && status != :running
         # Create cloud
      end

   end


   # Makes sure the cloud is not running.
   def stop

      debug "Stopping cloud %s" % [resource[:name]]

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
