require 'yaml'

##
# Obtains the ips from the appscale.yaml file. It does NOT check whether
# the file has the proper format.

def appscale_yaml_parser(file)

   ips = {}

   tree = YAML::parse(File.open(file))
   
   if tree != nil

      tree = tree.transform

      # Default deployment (from appscale-tools/lib/node_layout.rb)
      controller = tree[:controller]
      servers = tree[:servers]

      if controller != nil
         puts "Controller at #{controller}"
         ips[controller] = 1
      end

      if servers != nil
         servers.each do |ip|
            puts "Server at #{ip}"
            ips[ip] = 1
         end
      end

      # Custom deployment (from appscale-tools/lib/node_layout.rb)
      master = tree[:master]
      appengine = tree[:appengine]
      database = tree[:database]
      login = tree[:login]
      open = tree[:open]
      zookeper = tree[:zookeper]
      memcache = tree[:memcache]
      
      if master != nil
         puts "Master at #{master}"
         ips[master] = 1
      end
      
      if appengine != nil
         appengine.each do |ip|
            puts "Appengine at #{ip}"
            ips[ip] = 1
         end
      end
      
      if database != nil
         database.each do |ip|
            puts "Database at #{ip}"
            ips[ip] = 1
         end
      end
      
      if login != nil
         login.each do |ip|
            puts "Login at #{ip}"
            ips[ip] = 1
         end
      end
      
      if open != nil
         open.each do |ip|
            puts "Open at #{ip}"
            ips[ip] = 1
         end
      end
      
      if zookeper != nil
         zookeper.each do |ip|
            puts "Zookeper at #{ip}"
            ips[ip] = 1
         end
      end
      
      if memcache != nil
         memcache.each do |ip|
            puts "Memcache at #{ip}"
            ips[ip] = 1
         end
      end
      
      puts "All IPs are:"
      ips.each do |ip,v|
         puts "IP: #{ip}"
      end
      return ips
   end
   
end
