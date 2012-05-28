require 'yaml'

##
# Obtains the IP addresses from the ip_file file. It does NOT check whether
# the file has the proper format.
# Different roles obtained from AppScale wiki:
#    http://code.google.com/p/appscale/wiki/Placement_Support

def appscale_yaml_ips(path)

   ips = []
   ip_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Default deployment (from appscale-tools/lib/node_layout.rb)
      controller = tree[:controller]
      servers =    tree[:servers]

      ip_roles[:controller] = get_elements(controller)
      ip_roles[:servers]    = get_elements(servers)

      ips = ips + ip_roles[:controller]
      ips = ips + ip_roles[:servers]
      
      # Custom deployment (from appscale-tools/lib/node_layout.rb)
      master =    tree[:master]
      appengine = tree[:appengine]
      database =  tree[:database]
      login =     tree[:login]
      open =      tree[:open]
      zookeeper = tree[:zookeeper]
      memcache =  tree[:memcache]
      
      ip_roles[:master]    = get_elements(master)
      ip_roles[:appengine] = get_elements(appengine)
      ip_roles[:database]  = get_elements(database)
      ip_roles[:login]     = get_elements(login)
      ip_roles[:open]      = get_elements(open)
      ip_roles[:zookeeper] = get_elements(zookeeper)
      ip_roles[:memcache]  = get_elements(memcache)
      
      ips = ips + ip_roles[:master]
      ips = ips + ip_roles[:appengine]
      ips = ips + ip_roles[:database]
      ips = ips + ip_roles[:login]
      ips = ips + ip_roles[:open]
      ips = ips + ip_roles[:zookeeper]
      ips = ips + ip_roles[:memcache]
      
      ips = ips.uniq
      
      file.close
      
      return ips, ip_roles
   end
   
end


# Obtains the disk images from the img_file file.
def appscale_yaml_images(path)

   img_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Default deployment (from appscale-tools/lib/node_layout.rb)
      controller = tree[:controller]
      servers    = tree[:servers]
      
      # Custom deployment (from appscale-tools/lib/node_layout.rb)
      master    = tree[:master]
      appengine = tree[:appengine]
      database  = tree[:database]
      login     = tree[:login]
      open      = tree[:open]
      zookeeper = tree[:zookeeper]
      memcache  = tree[:memcache]
      
      # Maybe we have been given only an image for all virtual machines
      all = tree[:all]
      
      if all == nil
         # Default deployment
         img_roles[:controller] = get_elements(controller)
         img_roles[:servers]    = get_elements(servers)
         
         # Custom deployment
         img_roles[:master]    = get_elements(master)
         img_roles[:appengine] = get_elements(appengine)
         img_roles[:database]  = get_elements(database)
         img_roles[:login]     = get_elements(login)
         img_roles[:open]      = get_elements(open)
         img_roles[:zookeeper] = get_elements(zookeeper)
         img_roles[:memcache]  = get_elements(memcache)
         
      else
         img_roles[:all] = get_elements(all)
      end
      
      file.close
      
      return img_roles
   end
   
end


# Transforms the given elements to an array.
def get_elements(array)

   elements = []
   if array != nil
      elements = array.to_a
   end
   return elements

end
