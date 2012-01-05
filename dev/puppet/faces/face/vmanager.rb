require 'puppet'
require 'puppet/face'
require 'libvirt'

Puppet::Face.define(:vmanager,'0.1.0') do
  license "Not defined yet"
  author "David Ceresuela <david.ceresuela@gmail.com>"

  summary "Virtual machine manager"
  description <<-DESC
  A virtual machine manager puppet face
  DESC

  option "--name NAME" do
    summary "The VM name"
  end
  
  option "--hypervisor HYPERVISOR" do
    summary "The hypervisor to connect to"
  end
  
  option "--file FILE" do
    summary "The XML containing the vm definition"
  end


  ##############################################################################
  action :test do
    when_invoked do |options|
      puts "Testing vmanager face. It responds."
    end
  end
  

  action :define do
    summary "Defines a new virtual machine from a XML file"
    
    when_invoked do |options|
      puts "== Defining a new virtual machine"
      define_from_XML(options[:file])
    end
  end
  

  action :list do
    summary "Lists all the defined virtual machines"
    
    examples <<-EX
    List all the available virtual machines:
  
    $ puppet vmanager list
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Listing virtual machines"
      puts "Hypervisor: #{options[:hypervisor]}"
      conn = connect_with_hypervisor()
      if conn
        list = conn.list_defined_domains()
        puts "Defined virtual machines:"
        list.each do |vm|
          puts "#{vm}"
        end
        conn.close
      else
        puts "Impossible to obtain a valid connection with the hypervisor"
      end
    end
  end
  
  
  ##############################################################################
  def config(options)
    if options.has_key?(:hypervisor)
      @hypervisor = options[:hypervisor]
    else
      # Default hypervisor
      @hypervisor = "qemu:///system"
    end
  end
  
  
  def connect_with_hypervisor()
    if check_hypervisor(@hypervisor)
      Libvirt::open(@hypervisor)
    else
      # Try to open a connection with a default hypervisor
      Libvirt::open("qemu:///system")
    end
  end
  
  
  def check_hypervisor(hypervisor)
    if hypervisor != nil
      regex = /^qemu:\/\/\/[a-z]+/
      if regex =~ hypervisor
        return hypervisor
      else
        puts "Invalid hypervisor"
        puts "Only qemu:///hypervisor hypervisors are allowed"
        return nil
      end
    end
  end
  
  
  def define_from_XML(file)
    puts "Not developed"
  end
  
  
end

