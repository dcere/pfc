puts "Starting AppScale. This is going to take some time ~3 min"
`ssh root@155.210.155.170 '/root/appscale-run-instances.sh ips.yaml david@gmail.com appscale > app.out 2> app.err'`
if $?.exitstatus == 0
   puts "Run succesfully"
else
   puts "Did not run"
end
