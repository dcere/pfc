require 'mcollective'
include MCollective::RPC

# MCollective files client used to manage files
class MCollectiveFilesClient < MCollectiveClient
   
   
   # Creates a new MCollective files client.
   def initialize(client)
      super(client)
   end
   
   
   # Cretes a new file in <path> containing <content>.
   def create_files(path, content)
   
      puts "Sending path and content via MCollective Files client"
      @mc.create(:path => path, :content => content)
      printrpcstats
   
   end
   
   
   # Deletes a file located at <path>.
   def delete_files(path)
   
      puts "Sending path via MCollective Files client"
      @mc.delete(:path => path)
      printrpcstats
   
   end
   
   
end
