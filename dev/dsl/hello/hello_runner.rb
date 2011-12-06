require 'hello_dsl.rb'

#puts "ARGV[0]: #{ARGV[0]}"
file = File.open(ARGV[0])
content = file.read
HelloDsl.new(content)
