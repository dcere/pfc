require 'mcollective'
include MCollective::RPC

class MCollectiveFilesClient < MCollectiveClient
   
   
   def initialize(client)
      super(client)
   end
   
   
   def create_files(path, content)
   
      puts "Sending path and content via MCollective client"
      @mc.create(:path => path, :content => content)
      printrpcstats
   
   end
   
   
   def delete_files(path)
   
      puts "Sending path via MCollective client"
      @mc.delete(:path => path)
      printrpcstats
   
   end
   
   
end
