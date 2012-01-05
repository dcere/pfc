require 'puppet'
require 'puppet/face'
require 'libvirt'

Puppet::Face.define(:vmanager,'0.1.0') do
  license "Not defined yet"
  author "David Ceresuela <daid.ceresuela@gmail.com>"

  summary "Virtual machine manager"
  description <<-DESC
  A virtual machine manager puppet face
  DESC

  option "--name NAME" do
    summary "The VM name"
  end
  
  option "--file FILE" do
    summary "The XML containing the vm definition"
  end

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
      conn = Libvirt::open("qemu:///system")
      list = conn.list_defined_domains()
      puts "== Defined virtual machines:"
      list.each do |vm|
        puts "#{vm}"
      end
      conn.close
    end
  end
  
  
  def define_from_XML(file)
    puts "Not developed"
  end
end

