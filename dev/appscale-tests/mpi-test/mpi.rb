output = neptune (
  :type => "mpi",
  :nodes_to_use => 1,
  :procs_to_use => 1,
  :output => "/tmp/mpi-output.txt",
  :code => "/tmp" )

puts "job started? #{output[:result]}"
puts "message: #{output[:msg]}"
