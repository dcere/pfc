metadata    :name        => "Cron management",
            :description => "",
            :author      => "David Ceresuela <david.ceresuela@gmail.com>",
            :license     => "",
            :version     => "0.1",
            :url         => "",
            :timeout     => 10

action "add_line", :description => "Add a new line to the cron file" do
   display :always

   input :path,
         :prompt      => "The file path",
         :description => "The file path",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   input :line,
         :prompt      => "The line",
         :description => "The line",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   output :success,
          :description => "Success on adding the line",
          :display_as  => "Line added"

end


action "delete_line", :description => "Delete all lines that match the regular expression" do
   display :always

   input :path,
         :prompt      => "The file path",
         :description => "The file path",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   input :regex,
         :prompt      => "The regular expression",
         :description => "The regular expression",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   output :success,
          :description => "Success on deleting lines",
          :display_as  => "Lines deleted"

   output :number,
          :description => "Number of deleted lines",
          :display_as  => "Number"

end
