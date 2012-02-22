class ConfigureGuest

  def initialize(name, img, mac)
    @name = name
    @img = "/var/tmp/dceresuela/" + img
    @mac = mac
    @uuid = `uuidgen`
    @memory = "1048576"
    #@guest_template = "./configuration-templates/virsh-guest.erb"
  end
  
  def get_binding
    binding()
  end
  
end

# Check arguments
unless ARGV.length == 3
  puts "A name, an img file and a mac address are needed to configure the guest"
  puts "Use: #{$0} <host name> <img file> <mac address>"
  exit
end

require 'erb'

# Create the configuration
myconf = ConfigureGuest.new(ARGV[0],ARGV[1], ARGV[2])

guest_template = File.open("./configuration-templates/virsh-guest.erb", 'r').read()

# Create the interfaces file
file_name = "./#{ARGV[0]}-description.xml"
file = File.open(file_name, 'w')
erb = ERB.new(guest_template)
file.write(erb.result(myconf.get_binding))
file.close
