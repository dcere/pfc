# Appscale parsing functions to obtain virtual machine's data from manifest's
# arguments.
# All different roles have been obtained from the node_layout file located at
# appscale-tools/lib/node_layout.rb
# There will be at most 1 controller, 1 master, and 1 login node.
# There will be at most N servers, appengine, database, open, zookeeper and
# memcache nodes.

################################################################################
# Default deployment
################################################################################

# Obtains the IP addresses and disk images from the resource[:controller],
# and resource[:servers] arguments.
# appscale { 'myappscale'
#    controller => ["155.210.155.73",
#                   "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    servers    => ["/etc/puppet/modules/appscale/files/servers-ips.txt",
#                   "/etc/puppet/modules/appscale/files/servers-imgs.txt"],
#    pool       => ["155.210.155.70"],
#    ensure     => running,
# }
def obtain_appscale_data_default(controller, servers)

   ips, ip_roles = appscale_parse_ips_default(controller, servers)
   img_roles     = appscale_parse_images_default(controller, servers)
   
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:controller], resource[:server] and
# resource[:database] arguments.
# appscale { 'myappscale'
#    controller => ["155.210.155.73",
#                   "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    servers    => ["/etc/puppet/modules/appscale/files/servers-ips.txt",
#                   "/etc/puppet/modules/appscale/files/servers-imgs.txt"],
#    pool       => ["155.210.155.70"],
#    ensure     => running,
# }
def appscale_parse_ips_default(controller, servers)

   ips_index = 0     # Because the IPs are in the first component of the
                     # controller and server arrays, and that is array[0]
   ips = []
   ip_roles = {}

   
   # Get the IPs that are under the "controller" and "servers" attributes
   ip_roles[:controller] = Array[controller[ips_index].chomp]
   ip_roles[:servers]    = get_from_file(servers[ips_index])
   
   # Add the IPs to the array
   ips = ips + ip_roles[:controller]
   ips = ips + ip_roles[:servers]
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:controller], and resource[:servers]
# arguments.
# appscale { 'myappscale'
#    controller => ["155.210.155.73",
#                   "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    servers    => ["/etc/puppet/modules/appscale/files/servers-ips.txt",
#                   "/etc/puppet/modules/appscale/files/servers-imgs.txt"],
#    pool       => ["155.210.155.70"],
#    ensure     => running,
# }
def appscale_parse_images_default(controller, servers)

   img_index = 1     # Because the images are in the second component of the
                     # controller and server arrays, and that is array[1]
   img_roles = {}

   
   # Get the disk images that are under the "controller" and "servers"
   # attributes
   img_roles[:controller] = Array[controller[img_index].chomp]
   img_roles[:servers]    = get_from_file(servers[img_index])
   
   return img_roles
   
end


################################################################################
# Custom deployment
################################################################################

# Obtains the IP addresses and disk images from the resource[:master],
# resource[:appengine], resource[:database], etc. arguments.
# appscale { 'myappscale'
#    master    => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    appengine => ["/etc/puppet/modules/appscale/files/appengine-ips.txt",
#                  "/etc/puppet/modules/appscale/files/appengine-imgs.txt"],
#    database  => ["/etc/puppet/modules/appscale/files/database-ips.txt",
#                  "/etc/puppet/modules/appscale/files/database-imgs.txt"],
#    login     => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    open      => ["/etc/puppet/modules/appscale/files/open-ips.txt",
#                  "/etc/puppet/modules/appscale/files/open-imgs.txt"],
#    pool      => ["155.210.155.70"],
#    ensure    => running,
# }
def obtain_appscale_data_custom(master, appengine, database, login, open,
                                zookeeper, memcache)

   puts "Parsing custom AppScale IPs"
   ips, ip_roles = appscale_parse_ips_custom(master, appengine, database, login,
                      open, zookeeper, memcache)
   puts "Parsing custom AppScale imgs"
   img_roles     = appscale_parse_images_custom(master, appengine, database,
                      login, open, zookeeper, memcache)
   
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:master], resource[:appengine],
# resource[:database], etc. arguments.
# appscale { 'myappscale'
#    ...
#    master    => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    appengine => ["/etc/puppet/modules/appscale/files/appengine-ips.txt",
#                  "/etc/puppet/modules/appscale/files/appengine-imgs.txt"],
#    database  => ["/etc/puppet/modules/appscale/files/database-ips.txt",
#                  "/etc/puppet/modules/appscale/files/database-imgs.txt"],
#    login     => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    open      => ["/etc/puppet/modules/appscale/files/open-ips.txt",
#                  "/etc/puppet/modules/appscale/files/open-imgs.txt"],
#    ...
# }
def appscale_parse_ips_custom(master, appengine, database, login, open,
                              zookeeper, memcache)

   ips_index = 0     # Because the IPs are in the first component of the
                     # controller and server arrays, and that is array[0]
   ips = []
   ip_roles = {}

   
   # Get the IPs that are under the "master", "appengine", "database", "login",
   # "open", "zookeeper" and "memcache" attributes
   ip_roles[:master]    = Array[master[ips_index].chomp]      unless master.nil?
   ip_roles[:appengine] = get_from_file(appengine[ips_index]) unless appengine.nil?
   ip_roles[:database]  = get_from_file(database[ips_index])  unless database.nil?
   ip_roles[:login]     = Array[login[ips_index].chomp]       unless login.nil?
   ip_roles[:open]      = get_from_file(open[ips_index])      unless open.nil?
   ip_roles[:zookeeper] = get_from_file(zookeeper[ips_index]) unless zookeeper.nil?
   ip_roles[:memcache]  = get_from_file(memcache[ips_index])  unless memcache.nil?

   # Add the IPs to the array
   ips = ips + (ip_roles[:master]    || []) # If it was nil, add the empty array
   ips = ips + (ip_roles[:appengine] || []) # (add nothing). If it was not nil,
   ips = ips + (ip_roles[:database]  || []) # add the IP addresses.
   ips = ips + (ip_roles[:login]     || [])
   ips = ips + (ip_roles[:open]      || [])
   ips = ips + (ip_roles[:zookeeper] || [])
   ips = ips + (ip_roles[:memcache]  || [])
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:master], resource[:appengine],
# resource[:database], etc. arguments.
# appscale { 'myappscale'
#    ...
#    master    => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    appengine => ["/etc/puppet/modules/appscale/files/appengine-ips.txt",
#                  "/etc/puppet/modules/appscale/files/appengine-imgs.txt"],
#    database  => ["/etc/puppet/modules/appscale/files/database-ips.txt",
#                  "/etc/puppet/modules/appscale/files/database-imgs.txt"],
#    login     => ["155.210.155.73",
#                  "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
#    open      => ["/etc/puppet/modules/appscale/files/open-ips.txt",
#                  "/etc/puppet/modules/appscale/files/open-imgs.txt"],
#    ...
# }
def appscale_parse_images_custom(master, appengine, database, login, open,
                                 zookeeper, memcache)

   img_index = 1     # Because the images are in the second component of the
                     # controller and server arrays, and that is array[1]
   img_roles = {}

   
   # Get the disk images that are under the "master", "appengine", "database",
   # "login", "open", "zookeeper" and "memcache" attributes
   img_roles[:master]    = Array[master[img_index].chomp]      unless master.nil?
   img_roles[:appengine] = get_from_file(appengine[img_index]) unless appengine.nil?
   img_roles[:database]  = get_from_file(database[img_index])  unless database.nil?
   img_roles[:login]     = Array[login[img_index].chomp]       unless login.nil?
   img_roles[:open]      = get_from_file(open[img_index])      unless open.nil?
   img_roles[:zookeeper] = get_from_file(zookeeper[img_index]) unless zookeeper.nil?
   img_roles[:memcache]  = get_from_file(memcache[img_index])  unless memcache.nil?

   return img_roles
   
end


################################################################################
# Auxiliar functions
################################################################################

# Gets all the file lines in an array.
def get_from_file(path)

   array = []
   file = File.open(path)
   if file != nil
      array = file.readlines.map(&:chomp)    # Discard the final '\n'
      file.close
   end

   return array

end
