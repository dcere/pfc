require 'mcollective'
include MCollective::RPC

class MCollectiveClient
   
   
   def initialize(client)
      @client = client
      @mc = rpcclient(@client)
   end
   
   
   def disconnect
      puts "Disconnecting MCollective client..."
      @mc.disconnect
   end
   
   
end
