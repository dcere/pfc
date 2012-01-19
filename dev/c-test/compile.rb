result = neptune (
  :type => "compile",
  :code => "/tmp/hello",
  :main => "/tmp/hello.c",
  :output => "/tmp/hellooutput" )

puts "out = #{result[:out]}"
puts "err = #{result[:err]}"
