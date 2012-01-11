require 'puppet'
require 'puppet/face'

Puppet::Face.define(:testface,'0.1.0') do
  license "Apache 2"
  author "David Ceresuela <david.ceresuela@gmail.com>"

  summary "Testing face"
  description <<-DESC
  This is a testing face
  DESC

  examples <<-EX
  ] puppet dcere
  EX

  option "--value VALUE" do
    summary "The new name"
  end

  @@value = "Initial value"
  @value2 = "Initial value2"

  action :test do
    when_invoked do |options|
      puts "Testing face"
    end
  end
  
  
  action :test_var do
    when_invoked do |options|
      puts "Value: #{@@value}"
      puts "Value2: #{@value2}"
      puts "Class value: #{@@class_value}"
    end
  end
  
  action :test_ass do
    when_invoked do |options|
      @@value = options[:value]
      @value = options[:value]
    end
  end 
  
  
end

