require 'mcollective'
include MCollective::RPC

puts "Running helloworld RPC agent"
mc = rpcclient("helloworld")
printrpc mc.echo(:msg => "Welcome to MCollective Simple RPC")
printrpcstats
mc.disconnect
puts "helloworld finished"
