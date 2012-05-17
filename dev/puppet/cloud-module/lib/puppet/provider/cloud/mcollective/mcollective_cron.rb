require 'mcollective'
include MCollective::RPC

class MCollectiveCronClient < MCollectiveClient
   
   
   def initialize(client)
      super(client)
   end
   
   
   def add_line(path, line)
   
      puts "Sending path and line via MCollective client"
      @mc.add_line(:path => path, :line => line)
      printrpcstats
   
   end
   
   
   def delete_line(path, string)
   
      puts "Sending path and regular expression via MCollective client"
      @mc.delete_line(:path => path, :regex => string)
      printrpcstats
   
   end
   
   
end
