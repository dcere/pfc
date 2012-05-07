require 'mcollective'
include MCollective::RPC


   puts "Creating client"
   mc = rpcclient("leader")
   puts "Retrieving nodes ids"
   printrpc mc.ask_id()
   printrpcstats
   puts "Disconnecting"
   #mc.disconnect

   id = "123"

   #puts "Creating client"
   #mc = rpcclient("leader")
   puts "Sending new leader information"
   printrpc mc.new_leader(:id => id)
   printrpcstats
   puts "Disconnecting"
   mc.disconnect

end
