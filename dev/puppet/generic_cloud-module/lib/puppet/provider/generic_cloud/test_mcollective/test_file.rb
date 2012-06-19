require 'mcollective'
include MCollective::RPC

def test
   puts "Creating client"
   mc = rpcclient("files")
   puts "Creating file"
   printrpc mc.create(:path => "/tmp/test", :content => "This is a test")
   printrpcstats
   puts "Disconnecting"
   mc.disconnect
end
