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
   
   
   def delete_line(path, regex)
   
      puts "Sending path and regular expression via MCollective client"
      string_regex = "#{regex}"
      puts "Regular expression = #{string_regex}"
      
      # Due to MCollective restrictions, a regular expression can not be passed
      # as an input parameter, so regex to string now, and later string to regex
      @mc.delete_line(:path => path, :regex => string_regex)
      printrpcstats
   
   end
   
   
end
