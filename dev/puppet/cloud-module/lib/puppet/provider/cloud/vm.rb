# Virtual machine class
class VM
   attr_accessor :vm
   
   def initialize(name,uuid,disk,mac)
   @vm = {
      :name => "#{name}",
      :uuid => "#{uuid}",
      :disk => "#{disk}",
      :mac  => "#{mac}"}
   end
   
   def get_binding
      binding()
   end
end


class VM_Name
   
   attr_reader :name
   
   def initialize(value=nil)
      @name = value ? value: "myvm"
   end
   
   
   def generate_array(many, start=1)
   
      result = []
      for i in start..many
         result << @name + "-" + i.to_s
      end
      return result
   
   end
   
   
end
