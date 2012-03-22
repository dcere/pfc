module MCollective
   module Agent
      class Files<RPC::Agent
         metadata    :name        => "File utilities for RPC Agents",
                     :description => "",
                     :author      => "David Ceresuela <david.ceresuela@gmail.com>",
                     :license     => "",
                     :version     => "0.1",
                     :url         => "",
                     :timeout     => 10

         # Basic file utilities
         action "create" do
            path = request[:path]
            content = request[:content]
            
            file = File.open(path, 'w')
            file.write(content)
            file.close
            
            reply[:success] = true
         end
      end
   end
end
