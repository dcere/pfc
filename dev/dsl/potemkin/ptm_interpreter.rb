def port p
  puts "Services for port: #{p}"
end

def respond (config, &block)
  puts "Listening on #{config[:resource]}, using block #{block}"
end

load "services.ptm"

