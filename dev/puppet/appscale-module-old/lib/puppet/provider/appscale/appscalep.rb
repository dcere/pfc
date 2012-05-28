Puppet::Type.type(:appscale).provide(:appscalep) do
   desc "Manages AppScale nodes."
   
   # Operating system restrictions
   confine :osfamily => "Debian"

   # Makes sure the node is running.
   def start
      puts "Checking the node..."
      
      unsolvable = false
      
      # Check the god process is running
      result = `ps axu`
      if result.include? "/usr/bin/god" #TODO Be aware of different installation paths
      
         puts "[app-p] god is running"

         # Check the appscale controller is running
         if result.include? "AppController/djinnServer.rb"
            # Everything looks right so let AppScale handle it.
            puts "[app-p] controller is running"
         else
            # Check the appscale controller existence
            unless File.exists?("/etc/init.d/appscale-controller") # TODO Same as above
               puts "[app-p] controller does not exist"
               unsolvable = true
            end
            # If god is running but the appcontroller is not, god will take care
         end

      else
         puts "[app-p] god is not running"
      
         if result.include? "AppController/djinnServer.rb"
            # Start god (the monitoring process)
            puts "[app-p] controller is running"
            if File.exists?("/etc/init.d/appscale-monitoring") # TODO Same as above
               `/etc/init.d/appscale-monitoring start`
            else
               unsolvable = true
            end
         else
            puts "[app-p] controller is not running"
            
            if resource[:type] == "controller" || resource[:type] == "master"
               # AppScale complete failure. AppScale has a single point of failure
               # ...
            end
            
            # Start the appscale controller
            if File.exists?("/etc/init.d/appscale-controller") # TODO Same as above
               `/etc/init.d/appscale-controller start`
            else
               unsolvable = true
            end
            # Start the appscale monitoring
            if File.exists?("/etc/init.d/appscale-monitoring") # TODO Same as above
               `/etc/init.d/appscale-monitoring start`
            else
               unsolvable = true
            end
         end
      end
      
      # If the error is unsolvable try to ???
      if unsolvable
         puts "[app-p] unsolvable error"
      end
      
   end


   # Makes sure the node is not running.
   def stop
      puts "Stopping the node"

      # Stop the appscale controller
      if File.exists?("/etc/init.d/appscale-controller") # TODO Same as above
         `/etc/init.d/appscale-controller stop`
      end

      # Stop the appscale monitoring
      if File.exists?("/etc/init.d/appscale-monitoring") # TODO Same as above
         `/etc/init.d/appscale-monitoring stop`
      end
      
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
