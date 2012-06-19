require 'mcollective'
include MCollective::RPC

def test

   # Connect
   puts "Creating client"
   mc = rpcclient("cronos")

   # Add line
   path = "/var/spool/cron/crontabs/root"

   puts "Adding test line"
   printrpc mc.add_line(:path => path, :line => "0 0 * * * echo 123")
   puts "Stats"
   puts "-----"
   printrpcstats

   # Delete line
   puts "Deleting line"
   resource = {}
   resource[:type] = "web"

   path = "/var/spool/cron/crontabs/root"
   string = "init-#{resource[:type]}"
   
   printrpc mc.delete_line(:path => path, :string => string)
   puts "Stats"
   puts "-----"
   printrpcstats
   
   # Disconnect
   puts "Disconnecting"
   mc.disconnect
end
