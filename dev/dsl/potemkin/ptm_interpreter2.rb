#!/usr/bin/env ruby

require 'potemkin'

def port p
  server = Server.new p
  Potemkin.instance.add_server server
end

def respond (config, default_content_type='text/html', &block)
  resource = config[:resource]

  h = Responder.new(resource) do | request, response |
    response['Content-Type'] = 'text/xml'
    block.call(request, response)
  end

  Potemkin.instance.servers.last.add_responder h
end

load "services.ptm"

Potemkin.instance.run

