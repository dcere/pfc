# Web parsing functions to obtain virual machine's data from manifest's
# arguments.

# Obtains the IP addresses and disk images from the resource[:balancer]
# resource[:server] and resource[:database] arguments.
# web { 'myweb'
#   ...
#   balancer => ["155.210.155.175", "/var/tmp/dceresuela/lucid-lb.img"],
#   server   => ["/etc/puppet/modules/web/files/server-ips.txt",
#                "/etc/puppet/modules/web/files/server-imgs.txt"],
#   database => ["155.210.155.177", "/var/tmp/dceresuela/lucid-db.img"],
#   ...
# }
def obtain_web_data(balancer, server, database)

   ips, ip_roles = web_parse_ips(balancer, server, database)
   img_roles     = web_parse_images(balancer, server, database)
   
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:balancer], resource[:server] and
# resource[:database] arguments.
# web { 'myweb'
#   ...
#   balancer => ["155.210.155.175", "/var/tmp/dceresuela/lucid-lb.img"],
#   server   => ["/etc/puppet/modules/web/files/server-ips.txt",
#                "/etc/puppet/modules/web/files/server-imgs.txt"],
#   database => ["155.210.155.177", "/var/tmp/dceresuela/lucid-db.img"],
#   ...
# }
def web_parse_ips(balancer, server, database)

   ips_index = 0     # Because the IPs are in the first component of the
                     # balancer, server and database arrays, and that is
                     # array[0]
   ips = []
   ip_roles = {}
   
   # Get the IPs that are under the "balancer", "server" and "database"
   # attributes
   ip_roles[:balancer] = []
   ip_roles[:balancer] << balancer[ips_index].chomp
   
   path = server[ips_index]
   ip_roles[:server] = get_from_file(path)
   
   ip_roles[:database] = []
   ip_roles[:database] << database[ips_index].chomp
   
   # Add the IPs to the array
   ips = ips + ip_roles[:balancer]
   ips = ips + ip_roles[:server]
   ips = ips + ip_roles[:database]
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:balancer], resource[:server] and
# resource[:database] arguments.
# web { 'myweb'
#   ...
#   balancer => ["155.210.155.175", "/var/tmp/dceresuela/lucid-lb.img"],
#   server   => ["/etc/puppet/modules/web/files/server-ips.txt",
#                "/etc/puppet/modules/web/files/server-imgs.txt"],
#   database => ["155.210.155.177", "/var/tmp/dceresuela/lucid-db.img"],
#   ...
# }
def web_parse_images(balancer, server, database)

   img_index = 1     # Because the images are in the second component of the
                     # balancer, server and database arrays, and that is
                     # array[1]
   img_roles = {}

   
   # Get the disk images that are under the "balancer", "server" and "database"
   # attributes
   img_roles[:balancer] = []
   img_roles[:balancer] << balancer[img_index].chomp
   
   path = server[img_index]
   img_roles[:server] = get_from_file(path)
   
   img_roles[:database] = []
   img_roles[:database] << database[img_index].chomp
   
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