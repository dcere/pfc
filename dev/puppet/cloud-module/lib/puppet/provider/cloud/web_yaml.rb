require 'yaml'

##
# Obtains the ips from the web.yaml file. It does NOT check whether
# the file has the proper format.

def web_yaml_parser(file)

   ips = []
   roles = {}

   tree = YAML::parse(File.open(file))
   
   if tree != nil

      tree = tree.transform

      # Classic deployment: load balancer + web servers + database
      balancer = tree[:balancer]
      server   = tree[:server]
      database = tree[:database]
      
      roles[:balancer] = get_ips(balancer)
      roles[:server]   = get_ips(server)
      roles[:database] = get_ips(database)
      
      ips = ips + roles[:balancer]
      ips = ips + roles[:server]
      ips = ips + roles[:database]
      
      ips = ips.uniq
      
      return ips, roles
   end
   
end

def get_ips(array)

   ips = []
   if array != nil
      ips = array.to_a
   end
   return ips

end
