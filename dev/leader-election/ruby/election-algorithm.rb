require './message.rb'

class ElectionAlgorithm
   
   attr_accessor :active
   
   def initialize(id=0, uuid=0)
      @id = id
      @uuid = uuid
      @engine = nil
      @peers = {}
      @active = true
   end
   
   
   def set_ids(id, uuid)
      @id = id
      @uuid = uuid
   end
   
   
   def set_engine(engine)
      @engine = engine
   end
   
   
   def set_net(peers)
      @peers = peers
   end
   
   
   def is_active?
      return @active
   end
   
   
   def call(message)
      puts "\n\n[#{@id}]: Received a new message: #{message}"
      if message.class == Message
         puts "[#{@id}]: It is a basic message"
         node = message.node
         uuid = message.uuid
         text = message.text
         puts "[#{@id}]: |#{node}: #{text}|"
         
         # This is not part of the election algorithm
         if text == "DISCOVERY"
            @peers[uuid] = node
            return
         end
         
         # Election algorithm
         if text == "ELECTION"
            puts "[#{@id}]: It is an election message"
            if node < @id
               # Say no to the node with lower ID
               puts "[#{@id}]: #{@id} -> #{node} : You are too little"
               m = Message.new(@id, @uuid, "ALIVE")
               puts "[#{@id}]: message created: "
               m.print
               @engine.send_to_peer(uuid, m)
               puts "[#{@id}]: message sent"
               
               # Start new election
               m = Message.new(@id, @uuid, "ELECTION")
               @engine.send_to_known_peers(m)
               
            elsif node > @id
               puts "#{@id} -> #{node} : You are my master"
               m = Message.new(@id, @uuid, "OK")
               puts "[#{@id}]: message created: "
               m.print
               @engine.send_to_peer(uuid, m)
               puts "[#{@id}]: message sent"
            else
               puts "[#{@id}]: node == #{node} and id == #{@id}"
            end
         
         elsif text == "ALIVE"
            # We are not going to be the leader
            puts "[#{@id}]: It is a negative answer message"
            if node > @id
               puts "[#{@id}]: #{@id} is no longer participating"
            end
            
         elsif text == "OK"
            # We might be the leader
            puts "[#{@id}]: It is an affirmative answer message"
            
            # Check if there are nodes with bigger ids
            bigger = false
            @peers.values.each do |node_id|
               if node_id > @id
                  bigger = true
               end
            end
            
            unless bigger
               puts "[#{@id}]: I am the leader"
               m = Message.new(@id, @uuid, "COORDINATOR")
               puts "[#{@id}]: message created: "
               m.print
               @engine.send_to_known_peers(m)
               puts "[#{@id}]: message sent"
               @active = false
            end
         
         elsif text == "COORDINATOR"
            puts "[#{@id}]: #{node} is the leader"
            @active = false
            
         else
            puts "[#{@id}]: Unrecognized pattern: #{text}"
         
         end
      else
         putsd("Unsupported message type received from peer. (#{message})")
      end
   end

end
