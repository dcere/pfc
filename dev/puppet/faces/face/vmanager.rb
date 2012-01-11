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
  # Actions
  ##############################################################################
  
  # Simple test
  ##############################################################################
  action :test do
    when_invoked do |options|
      puts "Testing vmanager face. It responds."
    end
  end
  
  # Domain definitions and description
  ##############################################################################
  action :define do
    summary "Define a new virtual machine from a XML file"
    
    examples <<-EX
    Define a virtual machine from a XML file:
  
    $ puppet vmanager define --file <XML-file>
    $ puppet vmanager define --file <XML-file> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Defining a new virtual machine"
      conn = connect_with_hypervisor()
      if conn
        conn.define_domain_xml(@file)
        puts "New domain defined"
        conn.close
      end
    end
  end
  
  
  action :undefine do
    summary "Undefine virtual machine"
    
    examples <<-EX
    Undefine a virtual machine:
  
    $ puppet vmanager undefine --name <virtual-machine-name>
    $ puppet vmanager undefine --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Defining a new virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          dom.undefine()
          puts "Domain undefined"
        else
          puts "Domain not found"
        end
        conn.close
      end
    end
  end
  
  
  action :describe do
    summary "XML description of a virtual machine"
    
    examples <<-EX
    Describe a virtual machine:
  
    $ puppet vmanager describe --name <virtual-machine-name>
    $ puppet vmanager describe --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Describing a virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          puts "XML description:"
          puts dom.xml_desc()
        else
          puts "Undefined domain"
        end
        conn.close
      end
    end
  end
  
  
  # Disk management
  ##############################################################################
  #action :copy_disk
  
  
  # Virtual machine: start, stop
  ##############################################################################
  action :start do
    summary "Start an already defined virtual machine"
    
    examples <<-EX
    Start an already defined virtual machine:
  
    $ puppet vmanager start --name <virtual-machine-name>
    $ puppet vmanager start --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Starting virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          dom.create()
          puts "Virtual machine started"
        else
          puts "Undefined domain"
        end
        conn.close
      end
    end
  end
  

  action :shutdown do
    summary "Shut down a running virtual machine"
    
    examples <<-EX
    Shut down a running virtual machine:
  
    $ puppet vmanager shutdown --name <virtual-machine-name>
    $ puppet vmanager shutdown --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Shutting down virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          dom.shutdown()
          puts "Virtual machine is being shut down"
        else
          puts "Undefined domain"
        end
        conn.close
      end
    end
  end
  
  
  action :reboot do
    summary "Reboot a running virtual machine (might be ignored by OS)"
    
    examples <<-EX
    Reboot a running virtual machine:
  
    $ puppet vmanager reboot --name <virtual-machine-name>
    $ puppet vmanager reboot --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Rebooting virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          dom.reboot()
          puts "Rebooting virtual machine"
        else
          puts "Undefined domain"
        end
        conn.close
      end
    end
  end
  
  
  action :destroy do
    summary "Destroy a running virtual machine. Hard power-off of the domain"
    
    examples <<-EX
    Destroy a running virtual machine:
  
    $ puppet vmanager destroy --name <virtual-machine-name>
    $ puppet vmanager destroy --name <virtual-machine-name> --hypervisor <hypervisor>
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Destroying virtual machine"
      conn = connect_with_hypervisor()
      if conn
        dom = conn.lookup_domain_by_name(@name)
        if dom != nil
          dom.destroy()
          puts "Virtual machine destroyed"
        else
          puts "Undefined domain"
        end
        conn.close
      end
    end
  end
  
  
  action :list do
    summary "List all the defined virtual machines"
    
    examples <<-EX
    List all the available virtual machines:
  
    $ puppet vmanager list
    EX
    
    when_invoked do |options|
      config(options)
      puts "== Listing virtual machines"
      conn = connect_with_hypervisor()
      if conn
        list_inactive = conn.list_defined_domains()
        list_active = conn.list_domains()
        puts "Defined virtual machines:"
        list_active.each do |vm|
          puts "#{vm}\t\tActive"
        end
        list_inactive.each do |vm|
          puts "#{vm}\t\tInactive"
        end
        conn.close
      else
        puts "Impossible to obtain a valid connection with the hypervisor"
      end
    end
  end
  
  
  ##############################################################################
  # Auxiliar functions
  ##############################################################################
  def config(options)
    if options.has_key?(:hypervisor)
      @hypervisor = options[:hypervisor]
    else
      # Default hypervisor
      @hypervisor = "qemu:///system"
    end
    @name = options[:name]
    @file = options[:file]
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
  
  
end
