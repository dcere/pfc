require 'rubygems'
require 'sinatra'
require 'active_record'
require 'erb'

ActiveRecord::Base.establish_connection(
   :adapter  => "mysql",
   :host     => "155.210.155.177",
   :username => "root-extern",
   :password => "mysql",
   :database => "mydb"
)

# Node
#  - id: Node ID. Primary key.
#  - ip: IP address.
#  - status: dead or alive.

class Node < ActiveRecord::Base
end

@@identifier = rand(100)
get '/' do
   @identifier = @@identifier
   @nodes = Node.all()
   erb :index
end
