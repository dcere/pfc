output = neptune (
  :type => "mpi",
  :nodes_to_use => 2,
  :procs_to_use => 2,
  :output => "/tmp/mpioutput2txt",
  :code => "/tmp" )

puts "job started? #{output[:result]}"
puts "message: #{output[:msg]}"
