Puppet::Type.type(:appscale).provide(:appscalep) do
   desc "Manages AppScale nodes."
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Makes sure the cloud is running.
   def start
      puts "Starting the node"
   end


   # Makes sure the cloud is not running.
   def stop
      puts "Stopping the node"
   end


   def status
      return :stopped
   end


   # Ensure methods
   def create
      return true
   end
   

   def destroy
      return true
   end


   def exists?
      return false
   end
   
   
end
