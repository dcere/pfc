require 'mcollective'
include MCollective::RPC

def mcollective_ask_id

   puts "Creatig client"
   mc = rpcclient("leader")
   puts "Retrieving nodes ids"
   printrpc mc.ask_id()
   printrpcstats
   puts "Disconnecting"
   mc.disconnect

end

def mcollective_new_leader(id)

   puts "Creatig client"
   mc = rpcclient("leader")
   puts "Sending new leader information"
   printrpc mc.new_leader(id)
   printrpcstats
   puts "Disconnecting"
   mc.disconnect

end
