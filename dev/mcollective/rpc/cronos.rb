module MCollective
   module Agent
      class Cronos<RPC::Agent
         metadata    :name        => "Cron management",
                     :description => "",
                     :author      => "David Ceresuela <david.ceresuela@gmail.com>",
                     :license     => "",
                     :version     => "0.1",
                     :url         => "",
                     :timeout     => 5

         # Cron files management functions
         action "add_line" do

            path = request[:path]
            line = request[:line]

            if File.exists?(path)
               # Check if the line already exists
               file = File.open(path, 'r')
               file.each_line do |file_line|
                  if file_line == line
                     reply[:success] = true
                     reply[:message] = "Line already existed"
                     file.close
                     return
                  end
               end
               
               # Line does not exist, so close the file (reading mode)
               file.close
               
               # Add the line if it does not exist
               file = File.open(path, 'a')
               file.puts(line)
               file.close
               
               # Execute crontab
               result = `crontab #{path}`
               if $?.exitstatus == 0
                  reply[:success] = true
                  reply[:message] = "Everything OK"
               else
                  reply[:success] = false
                  reply[:message] = "Could not execute crontab"
               end

            else
               # File does not exist
               file = File.open(path, 'w')
               if file != nil
                  file.puts(line)
                  file.close
                  
                  # Execute crontab
                  result = `crontab #{path}`
                  if $?.exitstatus == 0
                     reply[:success] = true
                     reply[:message] = "Everything OK"
                  else
                     reply[:success] = false
                     reply[:message] = "Could not execute crontab"
                  end
               else
                  reply[:success] = false
                  reply[:message] = "Could not create crontab/root file"
               end
            end
         end
         

         action "delete_line" do
            path  = request[:path]
            string = request[:string]
            regex = /^.*puppet.*apply.*#{string}.*$/     # Only delete puppet's
            copy = ""
            number = 0
            if File.exists?(path)
               file = File.open(path, 'r')
               
               # Read all the lines except the ones that match the regular expression
               file.each_line do |line|
                  if line.match(regex)
                     number += 1
                  else
                     copy << line
                  end
               end
               file.close
               
               # Write the copied lines to the file again
               file = File.open(path, 'w')
               file.puts(copy)
               file.close
               
               reply[:success] = true
               reply[:number]  = number
            else
               reply[:success] = false
               reply[:number]  = 0
            end
         end
         
         
      end
   end
end
