# Generic leader election methods for a distributed infrastructure
module CloudLeader
   
   ID_FILE     = "/tmp/cloud-id"
   LEADER_FILE = "/tmp/cloud-leader"
   
   # Do not use attr_reader because your id and your leader's id might change
   # during execution. The only thing that should not change are the files paths.
   
   # Gets the ID of the node by reading the node's id_file.
   def self.get_id(id_file = ID_FILE)
      
      if File.exists?(id_file)
         id_file = File.open(id_file, 'r')
         id = id_file.read().chomp().to_i()
         id_file.close
      else
         id = -1
      end
      return id
   
   end
   
   
   # Sets the ID of the node.
   def self.set_id(id, id_file = ID_FILE)
   
      file = File.open(id_file, 'w')
      file.puts(id)
      file.close
      
   end
   
   
   # Sets the leader ID in the node.
   def self.set_leader(leader, leader_file = LEADER_FILE)
   
      file = File.open(leader_file, 'w')
      file.puts(leader)
      file.close
      
   end
   
   
   # Gets the ID of the leader by reading the node's leader_file.
   def self.get_leader(leader_file = LEADER_FILE)
   
      if File.exists?(leader_file)
         leader_file = File.open(leader_file, 'r')
         leader = leader_file.read().chomp().to_i()
         leader_file.close
      else
         leader = -1
      end
      return leader
   
   end
   
   
   # Checks if the remote node has their ID file.
   def self.vm_check_id(vm, id_file = ID_FILE)
   
      command = "cat #{id_file} > /dev/null 2> /dev/null"
      out, success = CloudSSH.execute_remote(command, vm)
      return success
      
   end
   
   
   # Sets the node's ID on a remote node.
   def self.vm_set_id(vm, id, id_file = ID_FILE)
   
      command = "echo #{id} > #{id_file}"
      out, success = CloudSSH.execute_remote(command, vm)
      return success
      
   end


   # Sets the leader's ID on a remote node.
   def self.vm_set_leader(vm, leader, leader_file = LEADER_FILE)
   
      command = "echo #{leader} > #{leader_file}"
      out, success = CloudSSH.execute_remote(command, vm)
      return success
      
   end
      
      
end
