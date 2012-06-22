# Virtual machine class
class VM

   attr_accessor :vm
   
   
   # Creates a description of a virtual machine.
   def initialize(name, uuid, disk, mac, mem, ncpu)
      @vm = {
         :name => "#{name}",
         :uuid => "#{uuid}",
         :disk => "#{disk}",
         :mac  => "#{mac}",
         :mem  => "#{mem}",
         :ncpu => "#{ncpu}"}
   end
   
   
   # Provides binding for ERB templates.
   def get_binding
      binding()
   end
   
end
