# Generic leader election methods for a distributed infrastructure
class CloudLeader
   
   ID_FILE      = "/tmp/cloud-id"
   LEADER_FILE  = "/tmp/cloud-leader"
   LAST_ID_FILE = "/tmp/cloud-last-id"
   
   
   attr_reader :id, :leader, :last_id
   
   def initialize(id_file = ID_FILE, leader_file = LEADER_FILE,
                  last_id_file = LAST_ID_FILE)
   
      @id_file      = id_file
      @leader_file  = leader_file
      @last_id_file = last_id_file 
      
      @id      = init_id()
      @leader  = init_leader()
      @last_id = init_last_id()
      
   end
   
   
   #############################################################################
   private
   
   # Gets the node's ID by reading the node's id_file.
   def init_id()
      
      if File.exists?(@id_file)
         id_file = File.open(@id_file, 'r')
         id = id_file.read().chomp().to_i()
         id_file.close
      else
         id = -1
      end
      return id
   
   end
   
   
   # Gets the leader's ID by reading the node's leader_file.
   def init_leader()
   
      if File.exists?(@leader_file)
         leader_file = File.open(@leader_file, 'r')
         leader = leader_file.read().chomp().to_i()
         leader_file.close
      else
         leader = -1
      end
      return leader
   
   end
   
   
   # Gets the last defined ID in the ID file.
   def init_last_id()

      if File.exists?(@last_id_file)
         file = File.open(@last_id_file, 'r')
         id = file.read().chomp().to_i
         file.close
      else
         id = @id
      end
      return id

   end
   
   
   #############################################################################
   public
   
   # Sets the node's ID.
   def set_id(id)
   
      file = File.open(@id_file, 'w')
      file.puts(id)
      file.close
      @id = id
      
   end
   
   
   # Sets the leader's ID in the node.
   def set_leader(leader)
   
      file = File.open(@leader_file, 'w')
      file.puts(leader)
      file.close
      @leader = leader
      
   end
   
   
   # Sets last defined ID in the ID file.
   def set_last_id(id)

      file = File.open(@last_id_file, 'w')
      file.puts(id)
      file.close
      @last_id = id
      
   end
   
   
   # Checks if this node is leader.
   def leader?
      
      return @id == @leader && @id != -1
      
   end
   
   
   #############################################################################
   # Remote ID functions
   #############################################################################
   
   # Checks if the remote node has their ID file.
   def self.vm_check_id(user, vm, id_file = ID_FILE)
   
      command = "cat #{id_file} > /dev/null 2> /dev/null"
      out, success = CloudSSH.execute_remote(command, user, vm)
      return success
      
   end
   
   
   # Sets the node's ID on a remote node.
   def self.vm_set_id(user, vm, id, id_file = ID_FILE)
   
      command = "echo #{id} > #{id_file}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      return success
      
   end


   # Sets the leader's ID on a remote node.
   def self.vm_set_leader(user, vm, leader, leader_file = LEADER_FILE)
   
      command = "echo #{leader} > #{leader_file}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      return success
      
   end
   
end
