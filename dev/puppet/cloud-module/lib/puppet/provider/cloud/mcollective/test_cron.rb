require 'mcollective'
include MCollective::RPC

#def test
   puts "Creating client"
   mc = rpcclient("cronos")
#   puts "Deleting crontab entries"

#   resource = {}
#   resource[:type] = "web"

   path = "/var/spool/cron/crontabs/root"
#   regex = /^.*puppet.*apply.*init-#{resource[:type]}.*$/

#   puts "path = #{path}"
#   puts "regex = #{regex}"

#   printrpc mc.delete_line(:path => path, :regex => "#{regex}")
   printrpc mc.add_line(:path => path, :line => "0 0 * * * echo 123")
   puts "Stats"
   puts "-----"
   printrpcstats
   puts "Disconnecting"
   mc.disconnect
#end
