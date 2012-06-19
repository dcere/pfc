require 'mcollective'
include MCollective::RPC

# MCollective cron client used to manage crontab files
class MCollectiveCronClient < MCollectiveClient
   
   
   # Creates a new MCollective cron client.
   def initialize(client)
      super(client)
   end
   
   
   # Adds the line <line> to the crontab file located at <path>.
   def add_line(path, line)
   
      puts "Sending path and line via MCollective Cron client"
      @mc.add_line(:path => path, :line => line)
      printrpcstats
   
   end
   
   
   # Deletes lines that contain the <string> string in the crontab located at <path>.
   def delete_line(path, string)
   
      puts "Sending path and string via MCollective Cron client"
      @mc.delete_line(:path => path, :string => string)
      printrpcstats
   
   end
   
   
end
