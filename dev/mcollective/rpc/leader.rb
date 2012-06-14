module MCollective
   module Agent
      class Leader<RPC::Agent
         metadata    :name        => "Leader election algorithm",
                     :description => "Bully election algorithm",
                     :author      => "David Ceresuela <david.ceresuela@gmail.com>",
                     :license     => "",
                     :version     => "0.2",
                     :url         => "",
                     :timeout     => 10

         # Leader election algorithm actions
         action "ask_id" do
            file = File.open("/tmp/cloud-id", 'r')
            node_id = file.read().chomp()
            file.close
            
            reply[:node_id] = node_id
         end
         
         
         action "new_leader" do
            leader_id = request[:leader_id]
            file = File.open("/tmp/cloud-leader", 'w')
            file.write(leader_id)
            file.close
            
            reply[:success] = true
            reply[:leader] = leader_id
         end
         
         
      end
   end
end
