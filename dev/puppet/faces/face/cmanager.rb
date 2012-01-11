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
        create_instances(instances, path, img)
        start_instances()
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
  
  
  ##############################################################################
  def create_instances(instances, path, img)
    identifiers = generate_identifiers(img, instances.to_s.length)
    create_images(path, img, instances, identifiers)
  end
  
  
  def generate_identifiers(name, length)
    regex = /^(\S+)(\.\S+)$/
    identifiers = []
    if regex =~ name
      match = regex.match(name)
      base_name = match[1]
      extension = match[2]
      for i in (1..(10**length))
        id = base_name.to_s + i.to_s + extension.to_s
        identifiers.push(id)
      end
    else
      puts "Regex does not match"
    end
    return identifiers
  end
  
  
  def create_images(path, base_name, number, names)
    images = []
    source = path + "/" + base_name
    for i in (1..number)
      destination = path + "/" + names[i - 1]
      command = "cp " + source + " " + destination
      system(command)
      images.push(names[i - 1])
    end
    return images
  end
  
  
  ##############################################################################
  def start_instances()
  
  end
end
