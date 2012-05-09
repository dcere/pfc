require 'puppet/parser/ast/top_level_construct'

class Puppet::Parser::AST::Cloudres < Puppet::Parser::AST::TopLevelConstruct
  attr_accessor :name, :context

  def initialize(name, context = {}, &ruby_code)
    puts "[cloudres] Creating a new Cloudres..."
    @name = name
    @context = context
    @ruby_code = ruby_code
    puts "[cloudres] ...Cloudres created"
  end

  def instantiate(modname)
    puts "[cloudres] Instantiating a Cloudres..."
    new_cloudres = Puppet::Resource::Type.new(:cloudres, @name, @context.merge(:module_name => modname))
    new_cloudres.ruby_code = @ruby_code if @ruby_code
    puts "[cloudres] ...Cloudres instantiated"
    [new_cloudres]
  end
end
