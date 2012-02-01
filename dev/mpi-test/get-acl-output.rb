res = neptune (
  :type => "get-acl",
  :output => "/tmp/mpioutput2txt"
)

puts "result: #{res[:result]}"
puts "message: #{res[:msg]}"
puts "acl: #{res[:acl]}"
