Puppet::Type.newtype(:generic_cloud) do
   @doc = "Generic cloud description"


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

   newparam(:name) do      # TODO Why do I have to force it here instead of in
                           # the manifest with 'provider => web' ?
      desc "The cloud name"
      
      validate do |value|
         if value =~ /.*appscale.*/
            resource[:provider] = :appscale
         elsif value =~ /.*torque.*/
            resource[:provider] = :torque
         elsif value =~ /.*web.*/
            resource[:provider] = :web
         end
      end
      
      isnamevar
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
   # ...

end
