#!/usr/bin/env ruby

require 'node.rb'

chosen = 0
crash = 3
nodes = []

(0..3).each do |id|
   if id != crash
      nodes << Node.new(id, 2000 + id)
   end
end

nodes.each do |node|
   puts "Starting a new node"
   node.start
end

sleep(4)

nodes.each do |node|
   puts "Getting network information"
   node.get_information
end

puts "\nRunning the algorithm\n"
nodes.each do |node|
   node.run(chosen)
end
