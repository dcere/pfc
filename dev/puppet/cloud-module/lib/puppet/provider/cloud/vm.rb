# Virtual machine class
class VM

   #attr_accessor :vm # TODO Is it needed? Aren't we using the array?
   
   
   # Creates a description of a virtual machine.
   def initialize(name,uuid,disk,mac)
      @vm = {
         :name => "#{name}",
         :uuid => "#{uuid}",
         :disk => "#{disk}",
         :mac  => "#{mac}"}
   end
   
   
   # Provides binding for ERB templates.
   def get_binding
      binding()
   end
   
end


# Virtual machine name generator
class VM_Name
   
   attr_reader :name
   
   
   # Creates a generic prefix for virtual machines' names.
   def initialize(value=nil)
      @name = value ? value: "myvm"
   end
   
   
   # Generates an array of <many> names starting with suffix <start>.
   def generate_array(many, start=1)
   
      result = []
      for i in start..many
         result << @name + "-" + i.to_s
      end
      return result
   
   end
   
end
