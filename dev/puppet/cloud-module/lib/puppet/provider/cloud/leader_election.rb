class LeaderElection
   
   # Do not use attr_reader because your id and your leader's id might change
   # during execution. The only thing that should not change are the files paths.
   
   def initialize(id_file     = ID_FILE,
                  leader_file = LEADER_FILE,
                  yaml_file   = IDS_YAML)

      @id_file     = id_file
      @leader_file = leader_file
      @yaml_file   = yaml_file

   end


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
   
   
   def vm_set_id(vm, id)
   
      command = "ssh root@#{vm} 'echo #{id} > #{@id_file}'"
      result = `#{command}`
      return $?.exitstatus == 0
      
   end


   def vm_set_leader(vm, leader)
   
      command = "ssh root@#{vm} 'echo #{leader} > #{@leader_file}'"
      result = `#{command}`
      return $?.exitstatus == 0
      
   end
   
   
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
   
   
   def set_id_YAML(vm, id)
   
      require 'yaml'
      
      file = File.open(@yaml_file, 'a')
      file.puts("#{vm}: #{id}")
      file.close
      
   end
      
      
end
