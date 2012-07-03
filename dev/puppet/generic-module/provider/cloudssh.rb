# Generic ssh functions for a distributed infrastructure
module CloudSSH
   
   SSH_PATH = "/root/cloud/ssh"
   SSH_KEY = "id_rsa"

   # Generates a new ssh key to be used in all machines.
   def self.generate_ssh_key(path = SSH_PATH, file = SSH_KEY)
      
      puts "Creating #{path} directory..."
      result = `mkdir -p #{path}`
      unless $?.exitstatus == 0
         puts "Could not create #{path} directory"
      end
      
      puts "Deleting previous keys..."
      result = `rm -rf #{path}/*`
      unless $?.exitstatus == 0
         puts "Could not create #{path}/#{file} key"
      end
      
      puts "Generating key..."
      result = `ssh-keygen -t rsa -N '' -f #{path}/#{file}`
      unless $?.exitstatus == 0
         puts "Could not create #{path}/#{file} key"
      end
      
      puts "Evaluating agent and adding identity..."
      
      # Must be done in one command
      result = `eval \`ssh-agent\` ; ssh-add #{path}/id_rsa`
      unless $?.exitstatus == 0
         puts "Could not add #{path}/#{file} key"
      end

   end
   
   
   # Copies an ssh key to a machine.
   def self.copy_ssh_key(user, ip, password, path = SSH_PATH, file = SSH_KEY)
   
      command_path = "/etc/puppet/modules/generic-module/provider/"
      identity_file = "#{path}/#{file}.pub"     # Be careful, copy PUBLIC KEY
      if password != ""
         puts "password is not empty, using ssh_copy_id.sh shell script"
         result = `#{command_path}/ssh_copy_id.sh #{user}@#{ip} #{identity_file} #{password}`
         success = $?.exitstatus == 0
      else
         puts "password is empty, using ssh-copy-id command"
         result = `ssh-copy-id -i #{identity_file} #{user}@#{ip}`
         success = $?.exitstatus == 0
      end
      return result, success
   end
   
   
   # Executes a command on a remote machine.
   def self.execute_remote(command, user, ip, path = SSH_PATH, file = SSH_KEY)
   
      result = `ssh #{user}@#{ip} -i #{path}/#{file} '#{command}'`
      exit_code = $?.exitstatus
      success = (exit_code == 0)
      return result, success, exit_code
   end
   
   
   # Copies a file to a remote machine.
   def self.copy_remote(src_file, dst_ip, dst_file, dst_user = "root",
                        path = SSH_PATH, file = SSH_KEY)
   
      result = `scp -i #{path}/#{file} #{src_file} #{dst_user}@#{dst_ip}:#{dst_file}`
      success = $?.exitstatus == 0
      return result, success
   end
   
   
   # Gets a file from a remote machine.
   def self.get_remote(src_file, src_user, src_ip, dst_file,
                       path = SSH_PATH, file = SSH_KEY)
   
      result = `scp -i #{path}/#{file} #{src_user}@#{src_ip}:#{src_file} #{dst_file}`
      success = $?.exitstatus == 0
      return result, success
   
   end
end
