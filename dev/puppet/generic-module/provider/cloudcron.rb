# Manages cron files in remote machines
class CloudCron

   CRON_FILE = "/var/spool/cron/crontabs/root"

   def initialize(crontab = CRON_FILE)

      @crontab = crontab
      @time    = ""
      @command = ""
      @out     = ""
      @err     = ""

   end


   # Creates a new command
   def create_command(time, command, out, err)

      @time    = time
      @command = command
      @out     = out
      @err     = err

   end


   # Adds a line to the crontab file.
   def add_line(user, vm)

      line = "#{@time} #{@command} > #{@out} 2> #{@err}"
      command = "echo \"#{line}\" >> #{@crontab}"
      out, success = CloudSSH.execute_remote(command, user, vm)
      unless success
         puts "Impossible to add line in cron file #{@crontab} at #{vm}"
      end

      return success

   end


   # Deletes a line from the crontab file.
   def delete_line(user, vm)

      line = "#{@time} #{@command} > #{@out} 2> #{@err}"
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
