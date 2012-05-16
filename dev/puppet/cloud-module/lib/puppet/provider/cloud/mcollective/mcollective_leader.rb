require 'mcollective'
include MCollective::RPC

class MCollectiveLeaderClient
   
   
   def initialize(client)
      @client = client
      @mc = rpcclient(@client)
   end
   
   
   def ask_id
   
      ids = []
      regex = /^.*ID: (\d+).*$/
   
      puts "Retrieving nodes' ids via MCollective client..."
      output = Helpers.rpcresults @mc.ask_id()
      
      output.each_line do |line|
         m = line.match(regex)
         if m
            ids << m[1]
         end
      end
      
      return ids
   
   end
   
   
   def new_leader(id)
   
      puts "Sending new leader information via MCollective client..."
      output = @mc.new_leader(id)
      return output
   
   end
   
   
   def disconnect
      puts "Disconnecting MCollective client..."
      @mc.disconnect
   end
   
   
end
