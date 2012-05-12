require 'mcollective'
include MCollective::RPC

def mcollective_ask_id

   puts "Creating client"
   mc = rpcclient("leader")
   puts "Retrieving nodes' ids"
   output = mc.ask_id()
   puts "Disconnecting"
   mc.disconnect
   return output

end

def mcollective_new_leader(id)

   puts "Creating client"
   mc = rpcclient("leader")
   puts "Sending new leader information"
   output = mc.new_leader(id)
   puts "Disconnecting"
   mc.disconnect
   return output

end
