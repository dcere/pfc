require 'yaml'
require 'erb'

puts "Hi!"

#cloud = YAML::parse( File.open( "./cloud.yaml" ) )
#cloud = cloud.transform
#instances = cloud['instances']
#path = cloud['path']
#puts "Number of instances: #{instances}"
#puts "Path: #{path}"

class Name
  
  attr_accessor :name
  def initialize(name)
    @name = name
  end
  def get_binding
    binding()
  end
end
  
    
  template_path = "/home/david/Escritorio/PFC/dev/puppet/faces/test.erb"
  template = File.open(template_path, 'r').read()
  xmlfilename = "test.xml"
  puts "XML file name is: %s" % [xmlfilename]
  xmlfile = File.open(xmlfilename, 'w')
  erb = ERB.new(template)
  puts "erb created"
  myvm = Name.new("test")
  xmlfile.write(erb.result(myvm.get_binding))
  xmlfile.close
  puts "XML file closed"
