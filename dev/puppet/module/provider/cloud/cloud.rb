Puppet::Type.type(:cloud).provide(:cloud) do
   desc "Manages clouds formed by KVM virtual machines"

   commands :virtinstall => "/usr/bin/virt-install"
   commands :virsh => "/usr/bin/virsh"
   commands :grep => "/bin/grep"
   commands :ip => "/sbin/ip"

   # The provider is chosen by virt_type
   confine :feature => :libvirt

   has_features :pxe, :manages_behaviour, :graphics, :clocksync, :boot_params

   defaultfor :virtual => ["kvm", "physical", "xenu"]


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


   def exists?
      return true
   end
   
   
   def status
      return :stopped
   end
   
end
