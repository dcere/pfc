class VM_Name
   
   attr_reader :name
   
   def initialize(value=nil)
      @name = value ? value: "myvm"
   end
   
   
   def generate_array(many)
   
      result = []
      for i in 1..many
         result << @name + "-" + i.to_s
      end
      return result
   
   end
   
   
end
