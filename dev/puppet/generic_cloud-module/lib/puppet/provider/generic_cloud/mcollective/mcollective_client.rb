require 'mcollective'
include MCollective::RPC

# MCollective base client
class MCollectiveClient
   
   
   # Creates a new MCollective base client.
   def initialize(client)
      @client = client
      @mc = rpcclient(@client)
   end
   
   
   # Disconnects an MCollective client.
   def disconnect
      puts "Disconnecting MCollective client..."
      @mc.disconnect
   end
   
   
end
