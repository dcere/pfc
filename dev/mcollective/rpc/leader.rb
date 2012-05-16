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
            id = file.read()
            file.close
            
            id.chomp!
            reply[:id] = id
         end
         
         action "new_leader" do
            id = request[:id]
            file = File.open("/tmp/cloud-leader", 'w')
            file.write(request[:id])
            file.close
            
            reply[:success] = true
            reply[:leader] = id
         end
      end
   end
end
