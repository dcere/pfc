require 'yaml'

##
# Obtains the ips from the appscale.yaml file. It does NOT check whether
# the file has the proper format.

def appscale_yaml_parser(file)

   ips = []

   tree = YAML::parse(File.open(file))
   
   if tree != nil

      tree = tree.transform

      # Default deployment (from appscale-tools/lib/node_layout.rb)
      controller = tree[:controller]
      servers = tree[:servers]

      ips = ips + get_ips(controller)
      ips = ips + get_ips(servers)
      
      # Custom deployment (from appscale-tools/lib/node_layout.rb)
      master = tree[:master]
      appengine = tree[:appengine]
      database = tree[:database]
      login = tree[:login]
      open = tree[:open]
      zookeper = tree[:zookeper]
      memcache = tree[:memcache]
      
      ips = ips + get_ips(master)
      ips = ips + get_ips(appengine)
      ips = ips + get_ips(database)
      ips = ips + get_ips(login)
      ips = ips + get_ips(open)
      ips = ips + get_ips(zookeper)
      ips = ips + get_ips(memcache)
      
      ips = ips.uniq
      
      puts "All IPs are:"
      ips.each do |ip|
         puts "IP: #{ip}"
      end
      return ips
   end
   
end

def get_ips(array)

   ips = []
   if array != nil
      ips = array.to_a
   end
   return ips

end
