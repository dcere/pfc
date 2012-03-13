module MCollective
   module Agent
      class Filetest<RPC::Agent
         # Basic echo server
         def show_action
            validate :msg, String
            
            output = File.open("/tmp/fichero-de-prueba", 'w')
            bytes = output.write(request[:msg])
            output.close
            reply.data = "I wrote #{bytes} bytes"
         end
      end
   end
end

