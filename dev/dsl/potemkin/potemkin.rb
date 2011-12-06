class Responder
  attr_reader :resource

  def initialize(resource, &block)
    @resource = resource
    @block = block
  end

  def handle request, response
    @block.call request, response
  end
end


class Server
  attr_reader :port, :responders

  def initialize(port)
    @port = port
    @responders = []
  end

  def add_responder h
    @responders << h
  end

  def run
    @http_server =  WEBrick::HTTPServer.new( :Port => @port )
    @responders.each do |h|
      @http_server.mount_proc( h.resource ) do |request, response|
        h.handle(request, response)
      end
    end
    @http_server.start
  end

  def shutdown
    @http_server.shutdown
  end
end


require 'singleton'
class Potemkin
  include Singleton

  attr_reader :servers

  def initialize
    @servers = []
  end

  def add_server s
    @servers << s
  end

  def run
    threads = []
    @servers.each do |s|
      threads << Thread.new do
        s.run
      end
    end
    threads.each { |t| t.join }
  end

  def shutdown
    @servers.each {|s| s.shutdown }
  end
end
