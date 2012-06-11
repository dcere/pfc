require 'mcollective'
include MCollective::RPC

def test
   puts "Creating client"
   mc = rpcclient("leader")
   puts "Retrieving nodes ids"
   printrpc mc.ask_id()
   printrpcstats
   puts "Disconnecting"

   id = "123"
   puts "Sending new leader information"
   printrpc mc.new_leader(:id => id)
   printrpcstats
   puts "Disconnecting"
   mc.disconnect
end
