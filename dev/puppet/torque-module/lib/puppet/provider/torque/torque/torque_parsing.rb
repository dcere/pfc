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

   ips_index = 0
   ips = []
   ip_roles = {}

   
   # Get the IPs that are under the "head" and "compute" labels
   ip_roles[:head] = []
   ip_roles[:head] << head[ips_index].chomp
   
   path = compute[ips_index]
   file = File.open(path)
   if file != nil
      ip_roles[:compute] = []
      file.each_line do |line|
         ip_roles[:compute] << line.chomp
      end
   end
   
   # Add the IPs to the array
   ips = ips + ip_roles[:head]
   ips = ips + ip_roles[:compute]
   
   ips = ips.uniq
   
   file.close
   
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

   img_index = 1
   img_roles = {}

   
   # Get the disk images that are under the "head" and "compute" labels
   img_roles[:head] = []
   img_roles[:head] << head[img_index].chomp
   
   path = compute[img_index]
   file = File.open(path)
   if file != nil
      img_roles[:compute] = []
      file.each_line do |line|
         img_roles[:compute] << line.chomp
      end
   end
   
   file.close
   
   return img_roles
   
end
