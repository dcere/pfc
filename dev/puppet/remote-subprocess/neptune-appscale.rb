puts "Hello from main program"

# Thread
t1 = Thread.new do
   ips_yaml = "./ips.yaml"
   command = "/usr/local/appscale-tools/bin/appscale-run-instances --ips #{ips_yaml}"
   system "ssh -tt root@155.210.155.170 '#{command}'"
end
t1.join

puts "After this lovely conversation I must go."
