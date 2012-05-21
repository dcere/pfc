# Leader election helper methods
class LeaderElection
   
   # Do not use attr_reader because your id and your leader's id might change
   # during execution. The only thing that should not change are the files paths.
   
   # Creates a new LeaderElection object.
   def initialize(id_file     = ID_FILE,
                  leader_file = LEADER_FILE,
                  yaml_file   = IDS_YAML)

      @id_file     = id_file
      @leader_file = leader_file
      @yaml_file   = yaml_file

   end


   # Gets the ID of the node by reading the node's id_file.
   def get_id
      
      if File.exists?(@id_file)
         id_file = File.open(@id_file, 'r')
         id = id_file.read().chomp()
         id_file.close
      else
         id = -1
      end
      return id
   
   end
   
   
   # Sets the ID of the node.
   def set_id(id)
   
      file = File.open(@id_file, 'w')
      file.puts(id)
      file.close
      
   end
   
   
   # Gets the ID of the leader by reading the node's leader_file.
   def get_leader
   
      if File.exists?(@leader_file)
         leader_file = File.open(@leader_file, 'r')
         leader = leader_file.read().chomp()
         leader_file.close
      else
         leader = -1
      end
      return leader
   
   end
   
   
   # Sets the node's ID on a remote node.
   def vm_set_id(vm, id)
   
      command = "echo #{id} > #{@id_file}"
      out, success = CloudSSH.execute_remote(command, vm)
      return success
      
   end


   # Sets the leader's ID on a remote node.
   def vm_set_leader(vm, leader)
   
      command = "echo #{leader} > #{@leader_file}"
      out, success = CloudSSH.execute_remote(command, vm)
      return success
      
   end
   
   
   # Gets the ID of a node from the yaml_file.
   def get_id_YAML(vm)

      require 'yaml'
   
      if File.exists?(@yaml_file)

         file = File.open(@yaml_file, 'r')
         tree = YAML::parse(file)

         if tree != nil
            tree = tree.transform
            id = tree[vm]
         end
         return id
         
      else
         return -1
      end
   
   end
   
   
   # Sets the ID of a node on the yaml_file.
   def set_id_YAML(vm, id)
   
      require 'yaml'
      
      file = File.open(@yaml_file, 'a')
      file.puts("#{vm}: #{id}")
      file.close
      
   end
      
      
end
