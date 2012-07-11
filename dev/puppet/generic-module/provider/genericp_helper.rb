# Checks if a machine is alive
def alive?(ip)

   ping = "ping -q -c 1 -w 4"
   result = `#{ping} #{ip}`
   return $?.exitstatus == 0

end

# Gets all the roles a node has.
def get_vm_roles(roles, vm)

   # The roles array is a map of roles - IP addresses. The 'IP addresses' value
   # can be either a single value or an array of values.
   
   vm_roles = []
   roles.each do |role, ips|
      if ips == vm
         vm_roles << role
      elsif ips.is_a?(Array) && ips.include?(vm)
         vm_roles << role
      end
   end
   return vm_roles

end
