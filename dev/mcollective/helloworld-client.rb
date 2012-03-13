#!/usr/bin/ruby

require 'mcollective'
include MCollective::RPC

mc = rpcclient("helloworld")
printrpc mc.echo(:msg => "Welcome to MCollective Simple RPC")
printrpcstats
mc.disconnect
