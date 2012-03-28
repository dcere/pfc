Puppet::Type.newtype(:appscale) do
   @doc = "Manages AppScale nodes."

   feature :start,
      "Starts an AppScale node."

   feature :stop,
      "Stops an AppScale node."


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
   `running`: The node is running.
   `stopped`: The node is stopped.\n"
      newvalue(:stopped) do
         provider.stop
      end

      newvalue(:running) do
         provider.start
      end

   end

   newparam(:name) do
      desc "The node name"
   end
   
   newparam(:type) do
      desc "The type of node:
   `controller`: An AppScale controller node.
   `server`:     An AppScale server node.
   `master`:     An AppScale master node.
   `appengine`:  An AppScale appengine node.
   `database`:   An AppScale database node.
   `login`:      An AppScale login node.
   `open`:       An AppScale open node.
   `zookeeper`:  An AppScale zookeeper node.
   `memcache`:   An AppScale memcache node.\n"
      newvalues("controller", "server", "master", "appengine", "database",
         "login", "open", "zookeeper", "memcache")
   end 

end
