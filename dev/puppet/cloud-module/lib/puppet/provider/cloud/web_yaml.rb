require 'yaml'

##
# Obtains the ips from the web.yaml file. It does NOT check whether
# the file has the proper format.

def web_yaml_parser(file)

   ips = []

   tree = YAML::parse(File.open(file))
   
   if tree != nil

      tree = tree.transform

      # Classic deployment: load balancer + web servers + database
      balancer = tree[:balancer]
      servers =  tree[:servers]
      database = tree[:database]
      
      ips = ips + get_ips(balancer)
      ips = ips + get_ips(servers)
      ips = ips + get_ips(database)
      
      ips = ips.uniq
      
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
