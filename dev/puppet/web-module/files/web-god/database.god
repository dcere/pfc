#
# Borrowed from http://thewebfellas.com/blog/2008/2/12/a-simple-faith-monitoring-by-god
#

God.watch do |w|
  w.name = "mysql"
  w.interval = 30.seconds # default      
  w.start = "service mysql start"
  w.stop = "service mysql stop"
  w.restart = "service mysql restart"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  w.pid_file = "/var/lib/mysql/lucid-db.pid"
    
  w.behavior(:clean_pid_file)

  # determine the state on startup    
  w.transition(:init, { true => :up, false => :start }) do |on|      
    on.condition(:process_running) do |c|        
      c.running = true     
    end    
  end     

  # determine when process has finished starting    
  w.transition([:start, :restart], :up) do |on|      
    on.condition(:process_running) do |c|        
      c.running = true      
    end       
    # failsafe      
    on.condition(:tries) do |c|        
      c.times = 8        
      c.within = 2.minutes        
      c.transition = :start      
    end    
  end     

  # start if process is not running    
  w.transition(:up, :start) do |on|      
    on.condition(:process_exits)    
  end     

  # lifecycle    
  w.lifecycle do |on|      
    on.condition(:flapping) do |c|        
      c.to_state = [:start, :restart]        
      c.times = 5        
      c.within = 1.minute        
      c.transition = :unmonitored        
      c.retry_in = 10.minutes        
      c.retry_times = 5        
      c.retry_within = 2.hours      
    end    
  end
  
end
