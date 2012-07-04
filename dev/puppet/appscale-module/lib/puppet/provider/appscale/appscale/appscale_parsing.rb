# Appscale parsing functions to obtain virual machine's data from manifest's
# arguments.


################################################################################
# Default deployment
################################################################################

# Obtains the IP addresses and disk images from the resource[:controller],
# and resource[:servers] arguments.
# appscale { 'myappscale'
#   ...
# }
def obtain_appscale_data_default(controller, servers)

#                         master, appengine, database, login, open,
#                         zookeeper, memcache)

   ips, ip_roles = appscale_parse_ips_default(controller, servers)
   img_roles     = appscale_parse_images_default(controller, servers)
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:controller], resource[:server] and
# resource[:database] arguments.
# appscale { 'myappscale'
#   ...
# }
def appscale_parse_ips_default(controller, servers)

   ips_index = 0     # Because the IPs are in the first component of the
                     # controller and server arrays, and that is array[0]
   ips = []
   ip_roles = {}

   
   # Get the IPs that are under the "controller" and "servers" attributes
   ip_roles[:controller] = []
   ip_roles[:controller] << controller[ips_index].chomp
   
   path = servers[ips_index]
   file = File.open(path)
   if file != nil
      ip_roles[:servers] = []
      file.each_line do |line|
         ip_roles[:servers] << line.chomp
      end
      file.close
   end
   
   # Add the IPs to the array
   ips = ips + ip_roles[:controller]
   ips = ips + ip_roles[:servers]
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:controller], and resource[:servers]
# arguments.
# appscale { 'myappscale'
#   ...
# }
def appscale_parse_images_default(controller, servers)

   img_index = 1     # Because the images are in the second component of the
                     # controller and server arrays, and that is array[1]
   img_roles = {}

   
   # Get the disk images that are under the "controller" and "servers"
   # attributes
   img_roles[:controller] = []
   img_roles[:controller] << controller[img_index].chomp
   
   path = servers[img_index]
   file = File.open(path)
   if file != nil
      img_roles[:servers] = []
      file.each_line do |line|
         img_roles[:servers] << line.chomp
      end
   end
   
   file.close
   
   return img_roles
   
end

################################################################################
# Custom deployment
################################################################################

def obtain_appscale_data_custom(master, appengine, database, login, open,
                                zookeeper, memcache)

   ips, ip_roles = appscale_parse_ips_custom(master, appengine, database, login,
                      open, zookeeper, memcache)
   img_roles     = appscale_parse_images_custom(master, appengine, database,
                      login, open, zookeeper, memcache)
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:controller], resource[:server] and
# resource[:database] arguments.
# appscale { 'myappscale'
#   ...
# }
def appscale_parse_ips_custom(master, appengine, database, login, open,
                              zookeeper, memcache)

   ips_index = 0     # Because the IPs are in the first component of the
                     # controller and server arrays, and that is array[0]
   ips = []
   ip_roles = {}

   
   # Get the IPs that are under the "master", "appengine", "database", "login",
   # "open", "zookeeper" and "memcache" attributes
   ip_roles[:master] = []
   ip_roles[:master] << master[ips_index].chomp
   
   path = appengine[ips_index]
   file = File.open(path)
   if file != nil
      ip_roles[:appengine] = []
      file.each_line do |line|
         ip_roles[:appengine] << line.chomp
      end
      file.close
   end
   
   path = database[ips_index]
   file = File.open(path)
   if file != nil
      ip_roles[:database] = []
      file.each_line do |line|
         ip_roles[:database] << line.chomp
      end
      file.close
   end
   
   ip_roles[:login] = []
   ip_roles[:login] << login[ips_index].chomp
   
   path = open[ips_index]
   file = File.open(path)
   if file != nil
      ip_roles[:open] = []
      file.each_line do |line|
         ip_roles[:open] << line.chomp
      end
      file.close
   end
   
   # TODO zookeeper and memcache
   
   # Add the IPs to the array   
   ips = ips + ip_roles[:master]
   ips = ips + ip_roles[:appengine]
   ips = ips + ip_roles[:database]
   ips = ips + ip_roles[:login]
   ips = ips + ip_roles[:open]
   ips = ips + ip_roles[:zookeeper]
   ips = ips + ip_roles[:memcache]
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:controller], and resource[:servers]
# arguments.
# appscale { 'myappscale'
#   ...
# }
def appscale_parse_images_custom(master, appengine, database, login, open,
                                 zookeeper, memcache)

   img_index = 1     # Because the images are in the second component of the
                     # controller and server arrays, and that is array[1]
   img_roles = {}

   
   # Get the disk images that are under the "master", "appengine", "database",
   # "login", "open", "zookeeper" and "memcache" attributes
   img_roles[:master] = []
   img_roles[:master] << master[img_index].chomp
   
   path = appengine[img_index]
   file = File.open(path)
   if file != nil
      img_roles[:appengine] = []
      file.each_line do |line|
         img_roles[:appengine] << line.chomp
      end
      file.close
   end
   
   path = database[img_index]
   file = File.open(path)
   if file != nil
      img_roles[:database] = []
      file.each_line do |line|
         img_roles[:database] << line.chomp
      end
      file.close
   end
   
   img_roles[:login] = []
   img_roles[:login] << login[img_index].chomp
   
   path = open[img_index]
   file = File.open(path)
   if file != nil
      img_roles[:open] = []
      file.each_line do |line|
         img_roles[:open] << line.chomp
      end
      file.close
   end
   
   # TODO zookeeper and memcache
   
   return img_roles
   
end
