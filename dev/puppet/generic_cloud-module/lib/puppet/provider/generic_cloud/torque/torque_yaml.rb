require 'yaml'


# Obtains the IP addresses from the ip_file file. It does NOT check whether
# the file has the proper format.
def torque_yaml_ips(path)

   ips = []
   ip_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Deployment: head node + compute nodes
      head      = tree[:head]
      compute   = tree[:compute]
      
      # Get the IPs that are under the "head" and "compute" labels
      ip_roles[:head]      = get_elements(head)
      ip_roles[:compute]   = get_elements(compute)
      
      # Add the IPs to the array
      ips = ips + ip_roles[:head]
      ips = ips + ip_roles[:compute]
      
      ips = ips.uniq
      
      file.close
      
      return ips, ip_roles
   end
   
end


# Obtains the disk images from the img_file file.
def torque_yaml_images(path)

   img_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Deployment: head node + compute nodes
      head      = tree[:head]
      compute   = tree[:compute]
      
      # Maybe we have been given only an image for all virtual machines
      all       = tree[:all]
      
      if all == nil
         img_roles[:head]      = get_elements(head)
         img_roles[:compute]   = get_elements(compute)
      else
         img_roles[:all]       = get_elements(all)
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
