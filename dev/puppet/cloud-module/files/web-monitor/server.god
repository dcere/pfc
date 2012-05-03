God.watch do |w|
  w.name = "ruby-web3"
  w.interval = 30.seconds # default      
  w.start = "ruby /root/web/web3.rb"
  w.keepalive
end
