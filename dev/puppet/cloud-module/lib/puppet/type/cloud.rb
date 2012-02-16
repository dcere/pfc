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
   `running`:
   The cloud is running.
   `stopped`:
   The cloud is stopped."
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

   newparam(:instances) do
      desc "The number of instances"
   end
   
   newparam(:images) do
      desc "The qemu image names"
   end

end
