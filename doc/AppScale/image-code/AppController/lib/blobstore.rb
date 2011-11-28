#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__))
require 'helperfunctions'

# A class to wrap all the interactions with the blobstore server
class BlobServer
  SERVER_PORTS = [6106]
  def self.start(db_local_ip, db_local_port)
    blobserver = self.blob_script
    ports = self.server_ports
    ports.each { |blobserver_port|
      start_cmd = ["/usr/bin/python2.6 #{blobserver}",
            "-d #{db_local_ip}:#{db_local_port}",
            "-p #{blobserver_port}"].join(' ')

      stop_cmd = "pkill -9 blobstore_server"

      GodInterface.start(:blobstore, start_cmd, stop_cmd, blobserver_port)
    }
  end

  def self.stop
     GodInterface.stop(:blobstore)
  end

  def self.restart(my_ip, db_port)
    self.stop
    self.start(my_ip, db_port)
  end

  def self.name
    "as_blobserver"
  end


  def self.server_ports
      return SERVER_PORTS
  end

  def self.is_running(my_ip)
    ports = self.server_ports
    ports.each { |blobserver_port|
     `curl http://#{my_ip}:#{blobserver_port}/` 
    }
  end 

  def self.blob_script
    return "#{APPSCALE_HOME}/AppDB/blobstore/blobstore_server.py"
  end
end

