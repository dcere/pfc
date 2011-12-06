class HelloDsl
   def initialize(dsl_text)
      eval(dsl_text)
   end

   def hello(name)
      puts "Hello there #{name}"
   end
end
