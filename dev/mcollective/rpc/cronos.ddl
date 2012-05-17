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
         :prompt      => "The crontab file path.",
         :description => "The crontab file path.",
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
          :description => "Success on adding the line.",
          :display_as  => "Line added"

   output :message,
          :description => "Success or Error message.",
          :display_as  => "Message"

end


action "delete_line", :description => "Delete all lines that match the regular expression" do
   display :always

   input :path,
         :prompt      => "The crontab file path.",
         :description => "The crontab file path.",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   input :string,
         :prompt      => "The string that will be looked for in the crontab file entries." +
                         " Those entries will be deleted.",
         :description => "The string that will be looked for in the crontab file entries." +
                         " Those entries will be deleted.",
         :type        => :string,
         :validation  => '^.+$',
         :optional    => false,
         :maxlength   => 300

   output :success,
          :description => "Success on deleting lines.",
          :display_as  => "Lines deleted"

   output :number,
          :description => "Number of deleted lines.",
          :display_as  => "Number"

end
