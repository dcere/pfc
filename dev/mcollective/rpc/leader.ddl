metadata    :name        => "Leader election algorithm",
            :description => "Bully election algorithm",
            :author      => "David Ceresuela <david.ceresuela@gmail.com>",
            :license     => "",
            :version     => "0.2",
            :url         => "",
            :timeout     => 10

action "ask_id", :description => "Asks a node's id" do
   display :always
   
   output :node_id,
          :description => "Node's ID",
          :display_as  => "ID"

end

action "new_leader", :description => "Tells the leader's id to all nodes" do
   display :always
   
   input :leader_id,
         :prompt      => "Leader's id",
         :description => "Leader's id",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 10
   
   output :success,
          :description => "Success on receiving leader's ID",
          :display_as  => "Leader's ID received"
          
   output :leader,
          :description => "Leader's ID",
          :display_as  => "Leader's ID"
          
          

end
