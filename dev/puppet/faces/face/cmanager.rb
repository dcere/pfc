require 'puppet'
require 'puppet/face'
require 'libvirt'

Puppet::Face.define(:cmanager,'0.1.0') do
  license "Not defined yet"
  author "David Ceresuela <david.ceresuela@gmail.com>"

  summary "Cloud manager"
  description <<-DESC
  A cloud manager puppet face
  DESC

#  option "--name NAME" do
#    summary "The VM name"
#  end
#  
  option "--file FILE" do
    summary "The YAML containing the cloud definition"
  end


  ##############################################################################
  # Actions
  ##############################################################################
  
  # Simple test
  ##############################################################################
  action :test do
    when_invoked do |options|
      puts "Testing cmanager face. It responds."
    end
  end
  
  
  # Cloud management: start, stop
  ##############################################################################
  action :start do
    summary "Start an already defined virtual machine"
    
    examples <<-EX
    Start an already defined virtual machine:
  
    $ puppet vmanager start --file <YAML-file>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Starting cloud"
      cloud = YAML::parse( File.open( @file ) )
      if cloud != nil
        cloud = cloud.transform
        instances = cloud['instances']
        path = cloud['path']
        img = cloud['img']
        puts "Number of instances: #{instances}"
        puts "Image path: #{path}"
        puts "Base image: #{img}"
      else
        puts "File error"
      end
    end
  end
  
  
  ##############################################################################
  # Auxiliar functions
  ##############################################################################
  def config(options)
    @file = options[:file]
  end
  
  
end
