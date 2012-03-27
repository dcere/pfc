metadata    :name        => "File utilities for RPC Agents",
            :description => "",
            :author      => "David Ceresuela <david.ceresuela@gmail.com>",
            :license     => "",
            :version     => "0.1",
            :url         => "",
            :timeout     => 10

action "create", :description => "Create a file" do
    display :always

   input :path,
         :prompt      => "The file path",
         :description => "The file path",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   input :content,
         :prompt      => "The content of the file",
         :description => "The content of the file",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 3000

   output :success,
          :description => "Success on creating the file",
          :display_as => "File created"

end
