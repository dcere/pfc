require 'mcollective'
include MCollective::RPC

# MCollective leader client used to help with leader election algorithm
class MCollectiveLeaderClient < MCollectiveClient
   
   
   # Creates a new MCollective leader client.
   def initialize(client)
      super(client)
   end
   
   
   # Asks all nodes for their ID.
   def ask_id
   
      ids = []
      regex = /^.*ID: (\d+).*$/
   
      puts "Retrieving nodes' ids via MCollective Leader client"
      output = Helpers.rpcresults @mc.ask_id()
      
      puts "Complete output:"
      puts "---------------------------"
      puts "#{output}"
      puts "---------------------------"
      
      output.each_line do |line|
         m = line.match(regex)
         if m
            ids << m[1].to_i()      # Send them as integers
         end
      end
      
      return ids
   
   end
   
   
   # Sends all nodes the leader's ID.
   def new_leader(id)
   
      puts "Sending new leader information via MCollective Leader client"
      output = @mc.new_leader(:leader_id => id)
      return output
   
   end
   
   
end
