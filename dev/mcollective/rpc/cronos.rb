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
               file = File.open(path, 'a')
               file.puts(line)
               file.close
               reply[:success] = true
            else
               reply[:success] = false
            end
         end
         
         action "delete_line" do
#            path  = request[:path]
#            regex = Regexp.new(request[:regex])
#            copy = ""
#            number = 0
            reply[:success] = true
            reply[:number] = 666
            return
#            if File.exists?(path)
#               file = File.open(path, 'r')
#               
#               # Read all the lines except the ones that match the regular expression
#               file.each_line do |line|
#                  if line.match(regex)
#                     number += 1
#                  else
#                     copy << line
#                  end
#               end
#               file.close
#               
#               # Write the copied lines to the file again
#               file = File.open(path, 'w')
#               file.puts(copy)
#               file.close
#               
#               reply[:success] = true
#               reply[:number]  = number
#            else
#               reply[:success] = false
#               reply[:number]  = 0
#            end
         end
         
      end
   end
end
