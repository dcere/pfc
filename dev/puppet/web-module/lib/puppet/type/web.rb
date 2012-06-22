Puppet::Type.newtype(:web) do
   @doc = "Manages web clouds formed by KVM virtual machines."
   
   
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
   
   newparam(:vm_domain) do
      desc "The XML file with the virtual machine domain definition. " +
           "Libvirt XML format must be used"
   end
   
   newproperty(:pool, :array_matching => :all) do
      desc "The pool of physical machines"
   end

   
   # Virtual machine parameters
   newparam(:vm_mem) do
      desc "The virtual machine's maximum amopunt of memory. " + 
           "In KiB: 2**10 (or blocks of 1024 bytes)."
      defaultto "1048576"
   end
   
   newparam(:vm_ncpu) do
      desc "The virtual machine's number of CPUs"
      defaultto "1"
   end
   
   
   # Infrastructure parameters

   newparam(:pm_user) do
      desc "The physical machine user. It must have proper permissions"
      defaultto "dceresuela"
   end

   newparam(:starting_mac_address) do
      desc "Starting MAC address for new virtual machines"
      defaultto "52:54:00:01:00:00"
   end

   newparam(:root_password) do
      desc "Virtual machines' root password"
      defaultto "root"
   end


   # Web parameters
   
   newproperty(:balancer, :array_matching => :all) do
      desc "The bañancer node's information"
   end
   
   newproperty(:server, :array_matching => :all) do
      desc "The compute nodes' information"
   end
   
   newproperty(:database, :array_matching => :all) do
      desc "The head node's information"
   end

end
