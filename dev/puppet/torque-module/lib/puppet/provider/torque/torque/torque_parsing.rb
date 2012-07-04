# Torque parsing functions to obtain virual machine's data from manifest's
# arguments.

# Obtains the IP addresses and disk images from the resource[:head] and
# resource[:compute] arguments.
# torque { 'mytorque'
#   ...
#   head => ["155.210.155.73", "/var/tmp/master.img"],
#   compute => ["/files/compute-ip.txt", "/files/compute-img.txt"],
#   ...
# }
def obtain_torque_data(head, compute)

   ips, ip_roles = torque_parse_ips(head, compute)
   img_roles     = torque_parse_images(head, compute)
   return ips, ip_roles, img_roles

end


# Obtains the IP addresses from the resource[:head] and resource[:compute]
# arguments.
# torque { 'mytorque'
#   ...
#   head => ["155.210.155.73", "/var/tmp/master.img"],
#   compute => ["/files/compute-ip.txt", "/files/compute-img.txt"],
#   ...
# }
def torque_parse_ips(head, compute)

   ips_index = 0     # Because the IPs are in the first component of the head
                     # and compute arrays, and that is array[0]
   ips = []
   ip_roles = {}
   
   # Get the IPs that are under the "head" and "compute" attributes
   ip_roles[:head] = []
   ip_roles[:head] << head[ips_index].chomp
   
   path = compute[ips_index]
   ip_roles[:compute] = get_from_file(path)
   
   # Add the IPs to the array
   ips = ips + ip_roles[:head]
   ips = ips + ip_roles[:compute]
   
   ips = ips.uniq
   
   return ips, ip_roles
   
end


# Obtains the disk images from the resource[:head] and resource[:compute]
# arguments.
# torque { 'mytorque'
#   ...
#   head => ["155.210.155.73", "/var/tmp/master.img"],
#   compute => ["/files/compute-ip.txt", "/files/compute-img.txt"],
#   ...
# }
def torque_parse_images(head, compute)

   img_index = 1     # Because the images are in the first component of the head
                     # and compute arrays, and that is array[1]
   img_roles = {}

   
   # Get the disk images that are under the "head" and "compute" attributes
   img_roles[:head] = []
   img_roles[:head] << head[img_index].chomp
   
   path = compute[img_index]
   img_roles[:compute] = get_from_file(path)
   
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