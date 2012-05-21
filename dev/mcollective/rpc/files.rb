module MCollective
   module Agent
      class Files<RPC::Agent
         metadata    :name        => "File utilities for RPC Agents",
                     :description => "",
                     :author      => "David Ceresuela <david.ceresuela@gmail.com>",
                     :license     => "",
                     :version     => "0.3",
                     :url         => "",
                     :timeout     => 10

         # Basic file utilities
         action "create" do
            path = request[:path]
            content = request[:content]
            
            file = File.open(path, 'w')
            if file != nil
               file.write(content)
               file.close
               
               reply[:success] = true
            else
               reply[:success] = false
            end
         end
         
         
         action "append" do
            path = request[:path]
            content = request[:content]
            
            file = File.open(path, 'a')
            if file != nil
               file.puts(content)
               file.close
               
               reply[:success] = true
            else
               reply[:success] = false
            end
         end
         
         
         action "append_check" do
            path = request[:path]
            content = request[:content]
            
            file = File.open(path, 'r')
            if file != nil
               file.each_line do |file_line|
                  if file_line == line
                     reply[:success] = true
                     file.close
                     return
                  end
               end
               
               # Line does not exist, so close the file (reading mode)
               file.close
            else
               reply[:success] = false
               return
            end
            
            # Add the line if it does not exist
            file = File.open(path, 'a')
            if file != nil
               file.puts(line)
               file.close
               reply[:success] = true
               return
            else
               reply[:success] = false
            end

         end
         
         
         action "delete" do
            path = request[:path]
            File.delete(path)
            reply[:success] = true
         end
         
         
      end
   end
end
