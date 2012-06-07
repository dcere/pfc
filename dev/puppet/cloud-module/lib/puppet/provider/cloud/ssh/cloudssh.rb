# Generic monitor functions for a distributed infrastructure
module CloudSSH
   
   SSH_PATH = "/root/cloud/ssh"
   SSH_KEY = "id_rsa"

   # Generates a new ssh key to be used in all machines
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
   
   
   def self.copy_ssh_key(ip, password, path = SSH_PATH, file = SSH_KEY)
   
      puts "Copying ssh key..."
      command_path = "/etc/puppet/modules/cloud/lib/puppet/provider/cloud/ssh"
      identity_file = "#{SSH_PATH}/#{SSH_KEY}"
      if password
         result = `#{command_path}/ssh_copy_id.sh root@#{ip} #{identity_file} #{password}`
         success = $?.exitstatus == 0
      else
         result = `ssh-copy-id -i #{identity_file} root@#{ip}`
         success = $?.exitstatus == 0
      end
      return result, success
   end
   
   
   def self.execute_remote(command, ip, path = SSH_PATH, file = SSH_KEY)
   
      result = `ssh root@#{ip} -i #{SSH_PATH}/#{SSH_KEY} '#{command}'`
      success = $?.exitstatus == 0
      return result, success
   end
   
   
   def self.copy_remote(src_file, ip, dst_file, path = SSH_PATH, file = SSH_KEY)
   
      result = `scp -i #{SSH_PATH}/#{SSH_KEY} #{src_file} root@#{ip}:#{dst_file}`
      success = $?.exitstatus == 0
      return result, success
   end
   
end
