Puppet::Type.newtype(:torque) do
   @doc = "Manages torque clouds formed by KVM virtual machines."

   feature :start,
      "Starts a cloud."

   feature :stop,
      "Stops a cloud."


   # General parameters   
   require '/etc/puppet/modules/generic-module/type/generic.rb'
   
   
   # Infrastructure parameters

   newproperty(:pm_user) do
      desc "The physical machine user. It must have proper permissions"
      defaultto "dceresuela"
   end

   newproperty(:starting_mac_address) do
      desc "Starting MAC address for new virtual machines"
      defaultto "52:54:00:01:00:00"
   end

   newproperty(:root_password) do
      desc "Virtual machines' root password"
      defaultto "root"
   end

end
