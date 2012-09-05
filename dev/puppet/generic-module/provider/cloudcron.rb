# Manages cron files in remote machines
class CloudCron

   CRON_FILE = "/var/spool/cron/crontabs/root"

   def initialize(crontab = CRON_FILE)

      @crontab = crontab

   end


   # Creates a new command line.
   def create_line(time, command, out = "/dev/null", err = "/dev/null")

      return "#{time} #{command} > #{out} 2> #{err}"

   end


   # Adds a line to the crontab file.
   def add_line(line, user, vm)
      
      # Check if it is already in the file
      command = "cat #{@crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      if out.include? line
         return true
      end
      
      # Add it if it is not
      command = "echo \"#{line}\" >> #{@crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to add line in cron file #{@crontab} at #{vm}"
      end

      return success

   end


   # Deletes a line from the crontab file.
   def delete_line(line, user, vm)

      command = "sed -i '/#{line}/d' #{@crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to delete line in cron file #{@crontab} at #{vm}"
      end

      return success

   end


   # Deletes a line containing the word <word> from the crontab file.
   def delete_line_with_word(word, user, vm)

      command = "sed -i '/#{word}/d' #{@crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to delete line with #{word} in " + 
              "cron file #{@crontab} at #{vm}"
      end

      return success

   end

end
