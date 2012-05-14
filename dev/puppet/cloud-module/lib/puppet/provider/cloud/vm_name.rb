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
