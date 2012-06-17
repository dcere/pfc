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

   newparam(:name) do
      desc "The cloud name"
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

end
