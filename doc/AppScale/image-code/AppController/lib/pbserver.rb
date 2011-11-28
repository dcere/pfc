#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__))
require 'helperfunctions'

# A class to wrap all the interactions with the PbServer
class PbServer
  NUM_PBSERVERS = 3

  server_ports = []
  NUM_PBSERVERS.times { |i|
    server_ports << 4000 + i
  }
  SERVER_PORTS = server_ports

  PROXY_PORT = 3999
  LISTEN_PORT = 8888
  LISTEN_SSL_PORT = 8443
  DBS_NEEDING_ONE_PBSERVER = ["mysql"]
  DBS_WITH_NATIVE_TRANSACTIONS = ["mysql"]

  def self.start(master_ip, db_local_ip, my_ip, table, zklocations)
    pbserver = self.pb_script(table)
    ports = self.server_ports(table)

    env_vars = { 
      'APPSCALE_HOME' => ENV['APPSCALE_HOME'],
      "MASTER_IP" => master_ip, 
      "LOCAL_DB_IP" => db_local_ip 
    }

    ports.each { |port|
      start_cmd = ["/usr/bin/python2.6 #{pbserver} -p #{port}",
          "--no_encryption --type #{table} -z \'#{zklocations}\'",
          "-s #{HelperFunctions.get_secret} -a #{my_ip} --key"].join(" ")

      stop_cmd = "pkill -9 appscale_server"

      GodInterface.start(:pbserver, start_cmd, stop_cmd, port, env_vars)
    }
  end

  def self.stop(table)
     GodInterface.stop(:pbserver)

     #ports = self.server_ports(table)
     #ports.each { |pbserver_port|
     #  Kernel.system "start-stop-daemon --stop --pidfile /var/appscale/appscale-appscaleserver-#{pbserver_port}.pid"
     #}
  end

  def self.restart(master_ip, my_ip, table, zklocations)
    self.stop
    self.start(master_ip, my_ip, table, zklocations)
  end

  def self.name
    "as_pbserver"
  end

  def self.public_directory
    "/root/appscale/AppDB/public"
  end

  def self.listen_port
    LISTEN_PORT
  end

  def self.listen_ssl_port
    LISTEN_SSL_PORT
  end

  def self.server_ports(table)
    if DBS_NEEDING_ONE_PBSERVER.include?(table)
      return SERVER_PORTS.first(1)
    else
      return SERVER_PORTS
    end
  end

  def self.proxy_port
    PROXY_PORT
  end
  
  def self.is_running(my_ip)
    `curl http://#{my_ip}:#{PROXY_PORT}` 
  end 

  def self.pb_script(table)
    if DBS_WITH_NATIVE_TRANSACTIONS.include?(table)
      return "#{APPSCALE_HOME}/AppDB/appscale_server_native_trans.py"
    else
      return "#{APPSCALE_HOME}/AppDB/appscale_server.py"
    end
  end
end

