Puppet::Type.newtype(:cloud) do
   @doc = "Manages clouds formed by KVM virtual machines."

   feature :start,
      "Starts a cloud."

   feature :stop,
      "Stops a cloud."


   # A base class for numeric Cloud parameters validation.
   class CloudNumericParam < Puppet::Property

      def numfix(num)
         if num =~ /^\d+$/
            return num.to_i
         elsif num.is_a?(Integer)
            return num
         else
            return false
         end
      end

      munge do |value|
         value.to_i
      end

      validate do |value|
         if numfix(value)
            return value
         else
            self.fail "%s is not a valid %s" % [value, self.class.name]
         end
      end

   end


   # General parameters
   
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
   end
   
   newparam(:type) do
      desc "The type of cloud:
   `appscale`: An AppScale cloud.
   `web`:      A classic web cloud.
   `jobs`:     A jobs cloud.\n"
      newvalues("appscale", "web", "jobs")
   end 
   
   newparam(:file) do
      desc "The file with the cloud description in YAML format"
   end
   
   newparam(:domain) do
      desc "The XML file with the virtual machine domain definition. Libvirt XML format must be used"
   end
   
   newproperty(:images, :array_matching => :all) do
      desc "The qemu image(s). You must either provide one image from which" +
         " copies shall be made or provide an image for every instance"
   end
   
   newproperty(:pool, :array_matching => :all) do
      desc "The pool of physical machines"
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
   
   newproperty(:root_password) do
      desc "Virtual machines' root password"
      defaultto "root"
   end
   
   # Jobs and webs parameters ...
end
