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
   
   newparam(:images) do
      desc "The qemu image names"
   end
   
   newparam(:pool) do
      desc "The pool of physical machines"
   end

end
