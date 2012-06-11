require 'yaml'


# Obtains the IP addresses from the ip_file file. It does NOT check whether
# the file has the proper format.
def web_yaml_ips(path)

   ips = []
   ip_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Classic deployment: load balancer + web servers + database
      balancer = tree[:balancer]
      server   = tree[:server]
      database = tree[:database]
      
      # Get the IPs that are under the "balancer", "server" and "database" labels
      ip_roles[:balancer] = get_elements(balancer)
      ip_roles[:server]   = get_elements(server)
      ip_roles[:database] = get_elements(database)
      
      # Add the IPs to the array
      ips = ips + ip_roles[:balancer]
      ips = ips + ip_roles[:server]
      ips = ips + ip_roles[:database]
      
      ips = ips.uniq
      
      file.close
      
      return ips, ip_roles
   end
   
end


# Obtains the disk images from the img_file file.
def web_yaml_images(path)

   img_roles = {}

   file = File.open(path)
   tree = YAML::parse(file)
   
   if tree != nil

      tree = tree.transform

      # Classic deployment: load balancer + web servers + database
      balancer = tree[:balancer]
      server   = tree[:server]
      database = tree[:database]
      
      # Maybe we have been given only an image for all virtual machines
      all      = tree[:all]
      
      if all == nil
         img_roles[:balancer] = get_elements(balancer)
         img_roles[:server]   = get_elements(server)
         img_roles[:database] = get_elements(database)
      else
         img_roles[:all]      = get_elements(all)
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
