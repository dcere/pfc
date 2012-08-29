# Manages the infrastructure of a cloud with KVM support.
class CloudInfrastructure

   # Constants
   VIRSH_CONNECT = "virsh -c qemu:///system"
   DOMAINS_FILE = "/tmp/defined-domains"


   #############################################################################
   # Domain functions
   #############################################################################


   # Writes the virtual machine's domain file.
   def write_domain(virtual_machine, domain_file_path, template_path)

      require 'erb'
      template = File.open(template_path, 'r').read()
      erb = ERB.new(template)
      domain_file = File.open(domain_file_path, 'w')
      domain_file.write(erb.result(virtual_machine.get_binding))
      domain_file.close

   end


   # Defines a domain for a virtual machine on a physical machine.
   def define_domain(domain_file_name, pm_user, pm)

      command = "#{VIRSH_CONNECT} define #{domain_file_name}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success
      
   end


   # Starts a domain on a physical machine.
   def start_domain(domain, pm_user, pm)

      command = "#{VIRSH_CONNECT} start #{domain}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success
      
   end


   # Saves the virtual machine's domain name in a file.
   def save_domain_name(domain, pm_user, pm)

      command = "echo #{domain} >> #{DOMAINS_FILE}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end


   # Shuts down a domain.
   def shutdown_domain(domain, pm_user, pm)

      command = "#{VIRSH_CONNECT} shutdown #{domain}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end


   # Undefines a domain.
   def undefine_domain(domain, pm_user, pm)

      command = "#{VIRSH_CONNECT} undefine #{domain}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end

end
