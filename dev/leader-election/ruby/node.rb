# Load up the library
require 'rubygems'
require 'journeta'
include Journeta
include Journeta::Common
include Journeta::Common::Shutdown

# And the required files
require './election-algorithm.rb'


class Node
   
   def initialize(id, port)
      @id = id
      @port = port
      @ea = ElectionAlgorithm.new
      @journeta = Journeta::Engine.new(:peer_port => @port, :peer_handler => @ea,
                                       :groups => ['bully'])
      @uuid = @journeta.uuid
      @ea.set_ids(@id, @uuid)
      @ea.set_engine(@journeta)
      stop_on_shutdown(@journeta)
   end
   
   
   def start
      @journeta.start
   end
   
   
   def get_information
      # The `known_peers` call allows you to access the registry of known available peers on the network.
      # The UUID associated which each peer will be unique accross the network.
      peers = @journeta.known_peers
      peers_net = {}
      if peers.size > 0
        puts "[#{@id}]: The following peers IDs are online..."
        peers.each do |uuid, peer|
          puts " #{uuid}; version #{peer.version}"
          peers_net[uuid] = -1
        end
      else
        puts 'No peers known. (Start another client!)'
      end
      
      # Get the network information
      @ea.set_net(peers_net)
      
      # Identify yourself to the network
      m = Message.new
      m.node = @id
      m.uuid = @uuid
      m.text = "DISCOVERY"
      @journeta.send_to_known_peers(m)
   end
   
   
   def run(chosen)      
      # If you are the chosen, start the election algorithm
      if @id == chosen
         puts "[#{@id}]: I'm the chosen"
         m = Message.new
         m.node = @id
         m.uuid = @uuid
         m.text = "ELECTION"
         @journeta.send_to_known_peers(m)
      end
      
      # Let the election happen
      while @ea.is_active?
         sleep(1)
      end
      
   end
   
   
   def stop
      @journeta.stop
   end
   
end
