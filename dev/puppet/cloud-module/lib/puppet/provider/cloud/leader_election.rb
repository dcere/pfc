class LeaderElection
   
   # Do not use attr_reader because your id and your leader's id might change
   # during execution. The only thing that should not change are the files paths.
   
   def initialize(id_file="/tmp/cloud-id", leader_id_file="/tmp/cloud-leader")
      @id_file = id_file
      @leader_id_file = leader_id_file
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
   
      if File.exists?(@leader_id_file)
         leader_id_file = File.open(@leader_id_file, 'r')
         leader_id = leader_id_file.read().chomp()
         leader_id_file.close
      else
         leader_id = -1
      end
      return leader_id
   
   end
   
   
   def vm_set_id(vm, id)
   
      command = "ssh root@#{vm} 'echo #{id} > #{@id_file}'"
      result = `#{command}`
      if $?.exitstatus == 0
         puts "#{vm} received ID: #{id}"
      else
         err "Impossible to set ID on #{vm}"
      end

   end


   def vm_set_leader(vm, leader)
   
      command = "ssh root@#{vm} 'echo #{id} > #{@leader_file}'"
      result = `#{command}`
      if $?.exitstatus == 0
         puts "#{vm} received leader's ID: #{id}"
      else
         err "Impossible to set ID on #{vm}"
      end

   end
   
   
end
