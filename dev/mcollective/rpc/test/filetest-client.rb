#!/usr/bin/env ruby
require 'mcollective'
include MCollective::RPC

mc = rpcclient("filetest")

input = File.open(ARGV.first)
indata = input.read()

printrpc mc.show(:msg => indata)
printrpcstats
mc.disconnect
