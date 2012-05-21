require 'mcollective'
include MCollective::RPC

# MCollective files client used to manage files
class MCollectiveFilesClient < MCollectiveClient
   
   
   # Creates a new MCollective files client.
   def initialize(client)
      super(client)
   end
   
   
   # Cretes a new file in <path> containing <content>.
   def create_file(path, content)
   
      puts "Sending path and content via MCollective Files client"
      @mc.create(:path => path, :content => content)
      printrpcstats
   
   end
   
   
   # Appends <content> to the file located at <path>.
   def append_content(path, content)
   
      puts "Sending path and content via MCollective Files client"
      @mc.append(:path => path, :content => content)
      printrpcstats
   
   end
   
   
   # Deletes a file located at <path>.
   def delete_file(path)
   
      puts "Sending path via MCollective Files client"
      @mc.delete(:path => path)
      printrpcstats
   
   end
   
   
end
