#!/usr/bin/ruby -w
# Programmer: Chris Bunch (cgb@cs.ucsb.edu)

require 'digest/sha1'
require 'fileutils'
require 'net/http'
require 'openssl'
require 'socket'
require 'timeout'
require 'yaml'

module Kernel
  def shell(command)
    return `#{command}`
  end
end

# A helper module that aggregates functions that are not part of Neptune's
# core functionality. Specifically, this module contains methods to scp
# files to other machines and the ability to read YAML files, which are
# often needed to determine which machine should be used for computation
# or to copy over code and input files.
module CommonFunctions
  # Copies a file to the Shadow node (head node) within AppScale. 
  # The caller specifies
  # the local file location, the destination where the file should be
  # placed, and the name of the key to use. The keyname is typically
  # specified by the Neptune job given, but defaults to ''appscale''
  # if not provided.
  def self.scp_to_shadow(local_file_loc,
                         remote_file_loc,
                         keyname,
                         is_dir=false,
                         file=File,
                         get_from_yaml=CommonFunctions.method(:get_from_yaml),
                         scp_file=CommonFunctions.method(:scp_file))

    shadow_ip = get_from_yaml.call(keyname, :shadow, file)
    ssh_key = file.expand_path("~/.appscale/#{keyname}.key")
    scp_file.call(local_file_loc, remote_file_loc, shadow_ip, ssh_key, is_dir)
  end 
 
  # Performs the actual remote copying of files: given the IP address
  # and other information from scp_to_shadow, attempts to use scp
  # to copy the file over. Aborts if the scp fails, which can occur
  # if the network is down, if a bad keyname is provided, or if the 
  # wrong IP is given. If the user specifies that the file to copy is
  # actually a directory, we append the -r flag to scp as well.
  def self.scp_file(local_file_loc, remote_file_loc, target_ip, public_key_loc,
    is_dir=false, file=File, fileutils=FileUtils, kernel=Kernel)
    cmd = ""
    local_file_loc = file.expand_path(local_file_loc)

    ssh_args = "-o StrictHostkeyChecking=no 2>&1"
    ssh_args << " -r " if is_dir

    public_key_loc = file.expand_path(public_key_loc)
    cmd = "scp -i #{public_key_loc} #{ssh_args} #{local_file_loc} root@#{target_ip}:#{remote_file_loc}"
    cmd << "; echo $? >> ~/.appscale/retval"

    retval_loc = file.expand_path("~/.appscale/retval")
    fileutils.rm_f(retval_loc)

    begin
      Timeout::timeout(-1) { kernel.shell("#{cmd}") }
    rescue Timeout::Error
      abort("Remotely copying over files failed. Is the destination machine" +
        " on and reachable from this computer? We tried the following" +
        " command:\n\n#{cmd}")
    end

    loop {
      break if file.exists?(retval_loc)
      sleep(5)
    }

    retval = (file.open(retval_loc) { |f| f.read }).chomp
    if retval != "0"
      abort("\n\n[#{cmd}] returned #{retval} instead of 0 as expected. Is " +
        "your environment set up properly?")
    end
    return cmd
  end

  # Given the AppScale keyname, reads the associated YAML file and returns
  # the contents of the given tag. The required flag (default value is true)
  # indicates whether a value must exist for this tag: if set to true, this
  # method aborts if the value doesn't exist or the YAML file is malformed.
  # If the required flag is set to false, it returns nil in either scenario
  # instead.
  def self.get_from_yaml(keyname, tag, required=true, file=File, yaml=YAML)
    location_file = file.expand_path("~/.appscale/locations-#{keyname}.yaml")
  
    if !file.exists?(location_file)
      abort("An AppScale instance is not currently running with the provided" +
        " keyname, \"#{keyname}\".")
    end
    
    begin
      tree = yaml.load_file(location_file)
    rescue ArgumentError
      if required
        abort("The yaml file you provided was malformed. Please correct any" +
          " errors in it and try again.")
      else
        return nil
      end
    end
    
    value = tree[tag]
    
    if value.nil? and required
      abort("The file #{location_file} is in the wrong format and doesn't" +
        " contain a #{tag} tag. Please make sure the file is in the correct" +
        " format and try again.")
    end

    return value
  end

  # Returns the secret key needed for communication with AppScale's
  # Shadow node. This method is a nice frontend to the get_from_yaml
  # function, as the secret is stored in a YAML file.
  def self.get_secret_key(keyname, required=true, file=File, yaml=YAML)
    return CommonFunctions.get_from_yaml(keyname, :secret, required, file, yaml)
  end
end
