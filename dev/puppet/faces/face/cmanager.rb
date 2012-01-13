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
        number_instances = cloud['instances']
        node = cloud['node']
        path = cloud['path']
        img = cloud['img']
        puts "Number of instances: #{number_instances}"
        puts "Node base name: #{node}"
        puts "Image path: #{path}"
        puts "Image base name: #{img}"
        instances = create_instances(number_instances, node, path, img)
        #start_instances(instances)
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
  def create_instances(instances, node, path, img)
    puts "== Creating node identifiers"
    node_identifiers = generate_node_identifiers(node, instances)
    puts "== Creating image identifiers"
    image_identifiers = generate_image_identifiers(img, instances)
    puts "== Creating images"
    create_images(path, img, instances, image_identifiers)
    puts "== Defining instances"
    define_instances(node_identifiers, image_identifiers)
  end
  
  
  def generate_node_identifiers(name, max)
    identifiers = []
    for i in (1..max)
      id = name.to_s + "-" + i.to_s
      identifiers.push(id)
    end
    return identifiers
  end
  
  
  def generate_image_identifiers(name, max)
    regex = /^(\S+)(\.\S+)$/
    identifiers = []
    if regex =~ name
      match = regex.match(name)
      base_name = match[1]
      extension = match[2]
      for i in (1..max)
        id = base_name.to_s + "-" + i.to_s + extension.to_s
        identifiers.push(id)
      end
    else
      puts "Regex does not match"
    end
    return identifiers
  end
  
  
  def create_images(path, base_name, max, names)
    source = path + "/" + base_name
    for i in (1..max)
      destination = path + "/" + names[i - 1]
      command = "cp " + source + " " + destination
      system(command)
    end
  end
  
  
  class VM
    attr_accessor :vm
    def initialize()
      @vm = {
        :name => "virtual",
        :uuid => "99589efb-bd79-4835-b489-002f893c7300",
        :memory => "4",
        :img_path => "/home/david",
        :img_path_lab => "/home/david",
        :mac => "52:54:00:00:de:ad"}
    end
    def get_binding
      binding()
    end
  end
  
  def define_instances(nodes, images)
  require 'erb'
    
    template_path = "/home/david/Escritorio/PFC/dev/puppet/faces/templates/template-lab_xml.erb"
    template = File.open(template_path, 'r').read()
    #for i in (1..nodes.count)
      i = 1
      xmlfilename = nodes[i - 1].to_s + ".xml"
      puts "XML file name is: %s" % [xmlfilename]
      xmlfile = File.open(xmlfilename, 'w')
      erb = ERB.new(template)
      puts "erb created"
      myvm = VM.new()
      xmlfile.write(erb.result(myvm.get_binding))
      xmlfile.close
      puts "XML file closed"
      system("puppet vmanager define --file " + xmlfilename)
    #end
  end
  
  
  ##############################################################################
  def start_instances()
    system("puppet vmanager test")
  end
  
  
  def define_instance()
  end
  
  
  def start_instance()
  end
  
  
  
  
end
