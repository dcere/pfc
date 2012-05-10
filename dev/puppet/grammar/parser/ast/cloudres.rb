require 'puppet/parser/ast/top_level_construct'

class Puppet::Parser::AST::Cloudres < Puppet::Parser::AST::TopLevelConstruct
  attr_accessor :name, :context

  def initialize(name, context = {}, &ruby_code)
    puts "[parser/ast/cloudres] Creating a new Cloudres..."
    @name = name
    @context = context
    @ruby_code = ruby_code
    puts "[parser/ast/cloudres] ...Cloudres created"
  end

  def instantiate(modname)
    puts "[parser/ast/cloudres] Instantiating a Cloudres..."
    new_cloudres = Puppet::Resource::Type.new(:cloudres, @name, @context.merge(:module_name => modname))
    new_cloudres.ruby_code = @ruby_code if @ruby_code
    puts "[parser/ast/cloudres] ...Cloudres instantiated"
    all_types = [new_cloudres]
    if code
      puts "[parser/ast/cloudres] Cloudres has resources inside"
      puts "[parser/ast/cloudres] Instantiating resources..."
      puts "[parser/ast/cloudres] Code: #{code} (Class = #{code.class}))"
      code.each do |nested_ast_node|
      puts "[parser/ast/cloudres] Checking #{nested_ast_node}"
        if nested_ast_node.respond_to? :instantiate
          puts "[parser/ast/cloudres] Instantiating #{nested_ast_node}"
          all_types += nested_ast_node.instantiate(modname)
        end
      end
    end
    return all_types
  end
  
  def code()
    @context[:code]
  end
  
end
