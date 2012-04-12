require 'rubygems'
require 'sinatra'
require 'active_record'
require 'erb'

ActiveRecord::Base.establish_connection(
   :adapter  => "mysql",
   :host     => "155.210.155.177",
   :username => "mysql",
   :password => "mysql",
   :database => "mydb"
)

# Node
#  - id: Node ID. Primary key.
#  - ip: IP address.
#  - status: dead or alive.

class Node < ActiveRecord::Base
end

get '/' do
   'Hello there!'
   @nodes = Node.all()
   erb :index
end



  
  
