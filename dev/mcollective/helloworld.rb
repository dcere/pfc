module MCollective
   module Agent
      class Helloworld<RPC::Agent
         # Basic echo server
         def echo_action
            validate :msg, String
            reply.data = request[:msg]
         end
      end
   end
end
