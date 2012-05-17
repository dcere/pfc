require 'mcollective'
include MCollective::RPC

class MCollectiveCronClient < MCollectiveClient
   
   
   def initialize(client)
      super(client)
   end
   
   
   def add_line(path, line)
   
      puts "Sending path and line via MCollective Cron client"
      @mc.add_line(:path => path, :line => line)
      printrpcstats
   
   end
   
   
   def delete_line(path, string)
   
      puts "Sending path and string via MCollective Cron client"
      @mc.delete_line(:path => path, :string => string)
      printrpcstats
   
   end
   
   
end
