require 'pty'
require 'expect'

$expect_verbose = true

ips_yaml = "./ips-launch.yaml"

command = "/usr/local/appscale-tools/bin/appscale-run-instances --ips #{ips_yaml}"

begin

   PTY.spawn(command) do |reader, writer, pid|
      begin
         writer.sync = true

         reader.expect(/e-mail address:/,60) do |output|
            writer.puts("david@mail.com")
         end
         
         reader.expect(/your new password:/,10) do |output|
            writer.puts("appscale")
         end
         
         reader.expect(/again to verify:/,10) do |output|
            writer.puts("appscale")
         end
         
         reader.each { |line| print line }
      rescue Errno::EIO
      end
   end
   
rescue PTY::ChildExited

   puts "The child process exited!"

end
