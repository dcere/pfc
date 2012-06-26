# Generic ssh functions for a distributed infrastructure
module CloudSSH2
   
   SSH_PATH = "cloud/ssh"
   SSH_KEY  = "id_rsa"

   # Generates a new ssh key to be used in all machines.
   def self.generate_ssh_key(user, path = SSH_PATH, file = SSH_KEY)
      
      puts "Creating #{path} directory..."
      if user == "root"
         user_path = "/root/#{path}"
      else
         user_path = "/home/#{user}/#{path}"
      end
      result = `mkdir -p #{user_path}`
      unless $?.exitstatus == 0
         puts "Could not create #{user_path} directory"
      end
      
      puts "Deleting previous keys..."
      result = `rm -rf #{user_path}/*`
      unless $?.exitstatus == 0
         puts "Could not create #{user_path}/#{file} key"
      end
      
      puts "Generating key..."
      result = `ssh-keygen -t rsa -N '' -f #{user_path}/#{file}`
      unless $?.exitstatus == 0
         puts "Could not create #{user_path}/#{file} key"
      end
      
      puts "Evaluating agent and adding identity..."
      
      # Must be done in one command
      result = `eval \`ssh-agent\` ; ssh-add #{user_path}/id_rsa`
      unless $?.exitstatus == 0
         puts "Could not add #{user_path}/#{file} key"
      end

   end
   
   
   # Copies an ssh key to a machine.
   def self.copy_ssh_key(user, ip, password, path = SSH_PATH, file = SSH_KEY)
   
      puts "Copying ssh key..."
      command_path = "/etc/puppet/modules/generic-module/provider/"
      
      if user == "root"
         user_path = "/root/#{path}"
      else
         user_path = "/home/#{user}/#{path}"
      end
      
      identity_file = "#{user_path}/#{file}"
      if password
         result = `#{command_path}/ssh_copy_id.sh #{user}@#{ip} #{identity_file} #{password}`
         success = $?.exitstatus == 0
      else
         result = `ssh-copy-id -i #{identity_file} #{user}@#{ip}`
         success = $?.exitstatus == 0
      end
      return result, success
   end
   
   
   # Executes a command on a remote machine.
   def self.execute_remote(command, user, ip, path = SSH_PATH, file = SSH_KEY)
   
      if user == "root"
         user_path = "/root/#{path}"
      else
         user_path = "/home/#{user}/#{path}"
      end
   
      result = `ssh #{user}@#{ip} -i #{user_path}/#{file} '#{command}'`
      exit_code = $?.exitstatus
      success = (exit_code == 0)
      return result, success, exit_code
   end
   
   
   # Copies a file to a remote machine.
   def self.copy_remote(src_file, user, ip, dst_file, path = SSH_PATH, file = SSH_KEY)
   
      if user == "root"
         user_path = "/root/#{path}"
      else
         user_path = "/home/#{user}/#{path}"
      end
   
      result = `scp -i #{user_path}/#{file} #{src_file} #{user}@#{ip}:#{dst_file}`
      success = $?.exitstatus == 0
      return result, success
   end
   
end
