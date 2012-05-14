require 'mcollective'
include MCollective::RPC

class MCollectiveLeaderClient
   
   
   def initialize(client)
      @client = client
      @mc = rpcclient(@client)
   end
   
   
   def ask_id
   
      puts "Retrieving nodes' ids via MCollective client"
      output = @mc.ask_id()
      return output
   
   end
   
   
   def new_leader(id)
   
      puts "Sending new leader information via MCollective client"
      output = @mc.new_leader(id)
      return output
   
   end
   
   
   def disconnect
      puts "Disconnecting MCollective client"
      @mc.disconnect
   end
   
   
end
