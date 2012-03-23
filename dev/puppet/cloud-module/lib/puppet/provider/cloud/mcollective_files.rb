require 'mcollective'
include MCollective::RPC

def mcollective_create_files(path, content)

   puts "Creatig client"
   mc = rpcclient("files")
   puts "Sending path and content"
   printrpc mc.create(:path => path, :content => content)
   printrpcstats
   puts "Disconnecting"
   mc.disconnect

end
