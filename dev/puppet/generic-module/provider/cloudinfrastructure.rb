module CloudInfrastructure

   # Constants

   VIRSH_CONNECT = "virsh -c qemu:///system"
   DOMAINS_FILE = "/tmp/defined-domains"


   #############################################################################
   # Domain functions
   #############################################################################


   # Writes the virtual machine's domain file.
   def self.write_domain(virtual_machine, domain_file_path, template_path)

      require 'erb'
      template = File.open(template_path, 'r').read()
      erb = ERB.new(template)
      domain_file = File.open(domain_file_path, 'w')
      domain_file.write(erb.result(virtual_machine.get_binding))
      domain_file.close

   end


   # Defines a domain for a virtual machine on a physical machine.
   def self.define_domain(pm_user, pm, vm_name, domain_file_name)

      command = "#{VIRSH_CONNECT} define #{domain_file_name}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success
      
   end


   # Starts a domain on a physical machine.
   def self.start_domain(pm_user, pm, vm_name)

      command = "#{VIRSH_CONNECT} start #{vm_name}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success
      
   end


   # Saves the virtual machine's domain name in a file.
   def self.save_domain_name(pm_user, pm, vm_name)

      command = "echo #{vm_name} >> #{DOMAINS_FILE}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end


   # Shuts down a domain.
   def self.shutdown_domain(domain, pm_user, pm)

      command = "#{VIRSH_CONNECT} shutdown #{domain}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end


   # Undefines a domain.
   def self.undefine_domains(domain, pm_user, pm)

      command = "#{VIRSH_CONNECT} undefine #{domain}"
      out, success = CloudSSH.execute_remote(command, pm_user, pm)
      return success

   end

end