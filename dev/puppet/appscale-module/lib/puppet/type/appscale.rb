Puppet::Type.newtype(:cloud) do
   @doc = "Manages clouds formed by KVM virtual machines."

   feature :start,
      "Starts a cloud."

   feature :stop,
      "Stops a cloud."

   
   ensurable do
      desc "The cloud's ensure field can assume one of the following values:
   `running`: The cloud is running.
   `stopped`: The cloud is stopped.\n"
      newvalue(:stopped) do
         provider.stop
      end

      newvalue(:running) do
         provider.start
      end

   end


   # General parameters   
   newparam(:name) do
      desc "The cloud name"
   end

   newparam(:ip_file) do
      desc "The file with the cloud description in YAML format"
   end

   newparam(:img_file) do
      desc "The file containing the qemu image(s). You must either provide " +
           "one image from which all copies shall be made or provide " +
           "an image for every instance"
   end

   newparam(:domain) do
      desc "The XML file with the virtual machine domain definition. Libvirt XML format must be used"
   end

   newproperty(:pool, :array_matching => :all) do
      desc "The pool of physical machines"
   end

   
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
   
   
   # AppScale parameters
   
   newproperty(:app_email) do
      desc "AppScale administrator e-mail"
      defaultto "david@gmail.com"
   end
   
   newproperty(:app_password) do
      desc "AppScale administrator password"
      defaultto "appscale"
   end
   
end
