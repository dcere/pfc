# Module to manage cron files in remote machines
module CloudCron

   CRON_FILE = "/var/spool/cron/crontabs/root"


   # Adds a line to the crontab file.
   def add_line(user, vm, line, crontab = CRON_FILE)

      command = "echo #{line} >> #{crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to add line in cron file #{crontab} at #{vm}"
      end

      return success

   end


   # Deletes a line from the crontab file.
   def delete_line(user, vm, line, crontab = CRON_FILE)

      command = "sed -i '/#{line}/d' #{crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to delete line in cron file #{crontab} at #{vm}"
      end

      return success

   end


   # Deletes a line containing the word <word> from the crontab file.
   def delete_line_with_word(user, vm, word, crontab = CRON_FILE)

      command = "sed -i '/#{word}/d' #{crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to delete line with #{word} in cron file #{crontab} at #{vm}"
      end

      return success

   end

end