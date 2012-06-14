require 'mcollective'
include MCollective::RPC

def test
   puts "Creatig client"
   mc = rpcclient("leader")

   puts "Retrieving nodes ids"
   printrpc mc.ask_id()
   printrpcstats
   puts "Disconnecting"

   id = "123"

   puts "Sending new leader information"
   out2 = Helpers.rpcresults mc.new_leader(:id => id)
   out3 = mc.new_leader(:id => id)
   puts "Disconnecting"
   mc.disconnect

   puts out3[0].agent
   puts out3[0].results[:sender]
   puts out3[1].results[:sender]

   puts "Output 2:"
   puts "---------"
   puts out2
end
