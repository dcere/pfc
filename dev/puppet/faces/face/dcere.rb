require 'puppet'
require 'puppet/face'

Puppet::Face.define(:dcere,'0.1.0') do
        license "Apache 2"
        author "David Ceresuela <daid.ceresuela@gmail.com>"
        
        summary "Testing faces with dcere face"
        description <<-DESC
        This is a testing face
        DESC

        examples <<-EX
        ] puppet dcere
        EX


        action :test do
                when_invoked do |options|
                        puts "Testing dcere face. It is nice."
                end
        end
end

