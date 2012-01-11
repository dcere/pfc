require 'yaml'

puts "Hi!"

cloud = YAML::parse( File.open( "./cloud.yaml" ) )
cloud = cloud.transform
instances = cloud['instances']
path = cloud['path']
puts "Number of instances: #{instances}"
puts "Path: #{path}"
