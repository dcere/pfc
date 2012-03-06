Puppet::Type.type(:cloud).provide(:cloudp) do
   desc "Manages clouds formed by KVM virtual machines"

   # Commands needed to make the provider suitable
   #commands :grep => "/bin/grep"
   #commands :ip => "/sbin/ip"
   commands :ping => "/bin/ping"

   # Operating system restrictions
   confine :osfamily => "Debian"


   # Makes sure the cloud is running.
   def start

      debug "[DBG] Starting cloud %s" % [resource[:name]]
      puts "Starting cloud %s" % [resource[:name]]
      
      # Check existence
      #if !exists?
      if true

         # Check pool of physical machines
         pm_all_up, pm_up, pm_down = check_pool()
         if !pm_all_up
            debug "[DBG] Some physical machines are down"
            pm_down.each do |pm|
               debug "[DBG] - #{pm}"
            end
            puts "Some physical machines are down"
         end
         
         # Obtain the virtual machines' IPs
         vm_ips = []
         if resource[:type].to_s == "appscale"
            debug "[DBG] It is an appscale cloud"
            info "It is an appscale cloud"
            #require './appscale_yaml.rb'
            #debug "[DBG] Files required"
            vm_ips = appscale_yaml_parser(resource[:file])
            debug "[DBG] File parsed"
            debug "[DBG] #{vm_ips}"
         elsif resource[:type].to_s == "web"
            debug "[DBG] It is a web cloud"
            info "It is a web cloud"
            vm_ips = []
         elsif resource[:type].to_s == "jobs"
            debug "[DBG] It is a jobs cloud"
            info "It is a jobs cloud"
            vm_ips = []
         else
            debug "[DBG] Cloud type undefined: #{resource[:type]}"
            debug "[DBG] Cloud type class: #{resource[:type].class}"
            err "Cloud type undefined: #{resource[:type]}"
            err "Cloud type class: #{resource[:type].class}"
         end
         
         
         # Distribute virtual machines among physical machines
         instances = vm_ips.count
         vm_per_pm = instances / pm_up.length
         quantity = {}
         pm_up.each do |pm|
            if pm == pm_up[-1]
               quantity[pm] = vm_per_pm + instances % pm_up.length
               puts "#{pm} will host #{quantity[pm]} virtual machines"
            else
               quantity[pm] = vm_per_pm
               puts "#{pm} will host #{quantity[pm]} virtual machines"
            end
         end
         
         # Check if it is reasonable to host that many virtual machines
         quantity.each do |pm, vm|
            if vm > 3
               debug "[DBG] #{pm} is hosting more than 3 virtual machines"
               warning "#{pm} is hosting more than 3 virtual machines"
            end
         end
         
         # Prepare virtual machines
         distribution = {}
         pm_up.each do |pm|
            distribution[pm] = vm_ips.shift(quantity[pm])
         end
         
         # Start virtual machines
         virsh_connect = "virsh -c qemu:///system"
         image = resource[:image]
         distribution.each do |pm, vms|
            ssh_connect = "ssh dceresuela@#{pm}"
            #vms.each do |vm|  #TODO Make it general enough
            result = `ssh_connect '#{virsh_connect} start #{image}'`
            if ($?.exitstatus == 0)
               debug "[DBG] #{image} started"
               info "#{image} started"
            else
               debug "[DBG] #{image} impossible to start"
               err "#{image} impossible to start"
            end
         end
         
         # Check virtual machines are alive
         alive = {}
         distribution.each do |pm, vms|
            vms.each do |vm|
               alive[vm] = 0
            end
         end
         
         while alive.has_value?(0)
            sleep(5)
            alive.keys.each do |vm|
               result = `ping -q -c 1 #{vm}`
               if ($?.exitstatus == 0)
                  debug "[DBG] #{vm} is up"
                  alive[vm] = 1
               else
                  debug "[DBG] #{vm} is down"
               end
            end
         end
         
         puts "Cloud started"
         
      else
         debug "[DBG] Cloud already started"
      end
      
   end


   # Makes sure the cloud is not running.
   def stop

      debug "[DBG] Stopping cloud %s" % [resource[:name]]

      if exists? && status == :running
         # Stop hosts
         virsh_connect = "virsh -c qemu:///system"
         images = resource[:images]
         images.each do |image|
            result = `#{virsh_connect} shutdown #{image}`
            if ($?.exitstatus == 0)
               debug "[DBG] #{image} was shut down"
            else
               debug "[DBG] #{image} impossible to shut down"
            end
         end
         
      end

   end


   def status
      return :stopped
   end


   # Ensure methods
   def create
      return true
   end
   

   def destroy
      return true
   end


   def exists?
      return false
   end
   

   #############################################################################
   # Auxiliar functions
   #############################################################################
   def check_pool
   
      all_up = true
      machines_up = []
      machines_down = []
      machines = resource[:pool]
      machines.each do |machine|
         result = `ping -q -c 1 #{machine}`
         if ($?.exitstatus == 0)
            debug "[DBG] #{machine} (PM) is up"
            machines_up << machine
         else
            debug "[DBG] #{machine} (PM) is down"
            all_up = false
            machines_down << machine
         end
      end
      return all_up, machines_up, machines_down
   end
   
   
   
   
   
   
end
