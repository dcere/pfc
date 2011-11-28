#!/usr/bin/ruby -w

require 'djinn'
require 'helperfunctions'

$:.unshift File.join(File.dirname(__FILE__), "..", "Neptune")
require "neptune_job_data"

require "appscale_helper"
require "erlang_helper"
require "go_helper"
require "mpi_helper"
require "mapreduce_helper"
require "r_helper"
require "ssa_helper"

ALLOWED_STORAGE_TYPES = ["appdb", "s3"]
NO_INPUT_NEEDED = ["ssa"]
NO_NODES_NEEDED = ["acl", "compile", "erlang", "go", "input", "output", "r"]

JOB_IN_PROGRESS = "job is in progress"
BAD_TYPE_MSG = "bad type of job asked for"
NOT_QUITE_AN_HOUR = 3300
INFINITY = 1.0 / 0

public

def neptune_start_job(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  touch_lock_file(job_data)
  Djinn.log_debug("got run request - #{job_data.inspect}")

  prejob_status = can_run_job(job_data)
  Djinn.log_debug("Pre-job status for job_data [#{job_data}] is [#{prejob_status}]")
  unless prejob_status == :ok
    return prejob_status
  end

  Thread.new {
    nodes_to_use = neptune_acquire_nodes(job_data)

    start_job(nodes_to_use, job_data)

    start_time = Time.now()
    master_node = nodes_to_use.first 
    run_job_on_master(master_node, nodes_to_use, job_data)
    end_time = Time.now()

    stop_job(nodes_to_use, job_data)

    neptune_release_nodes(nodes_to_use, job_data)

    name = get_job_name(job_data)
    num_nodes = nodes_to_use.length
    this_job = NeptuneJobData.new(name, num_nodes, start_time, end_time)
    if @neptune_jobs[name].nil?
      @neptune_jobs[name] = [this_job]
    else
      @neptune_jobs[name] << this_job
    end

    code = job_data['@code']
    dirs = code.split(/\//)
    code_dir = dirs[0, dirs.length-1].join("/")

    if code_dir != "/tmp"
      Djinn.log_debug("code is located at #{code_dir}")
      Djinn.log_run("rm -rf #{code_dir}")
    end
  }

  return "#{job_data['@type']} job is now running"
end

def neptune_is_job_running(job_data, secret)
  return BAD_SECRET_MSG unless valid_secret?(secret)
  return lock_file_exists?(job_data)
end

def neptune_put_input(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  Djinn.log_debug("requesting input")

  type = job_data["@type"]
  storage = job_data["@storage"]

  ["type", "storage", "local", "remote"].each { |item|
    if job_data["@#{item}"].nil?
      return "error: #{item} not specified"
    end
  }

  creds = neptune_parse_creds(storage, job_data)

  input_location = job_data["@remote"]

  local_fs_location = File.expand_path(job_data["@local"])

  loop {
    Djinn.log_debug("waiting for file #{local_fs_location} to exist")
    break if File.exists?(local_fs_location)
    sleep(1)
  }

  msg = "storing local file #{local_fs_location} with size " + 
    "#{File.size(local_fs_location)}, storing to #{input_location}"

  Djinn.log_debug(msg)

  ret_val = Repo.set_output(input_location, local_fs_location, storage, creds, is_file=true)

  # also, if we're running on hbase or hypertable, put a copy of the data
  # into HDFS for later processing via mapreduce

  table = @creds["table"]

  if ["hbase", "hypertable"].include?(table)
    unless my_node.is_db_master?
      db_master = get_db_master
      ip = db_master.private_ip
      ssh_key = db_master.ssh_key
      HelperFunctions.scp_file(local_fs_location, local_fs_location, ip, ssh_key)
    end

    cmd = "#{HADOOP} fs -put #{local_fs_location} #{input_location}"
    Djinn.log_debug("putting input in hadoop with command [#{cmd}]")
    run_on_db_master(cmd)
  end

  #FileUtils.rm_rf(local_fs_location)

  return ret_val
end

def neptune_get_output(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  Djinn.log_debug("requesting output")

  type = job_data["@type"]
  storage = job_data["@storage"]
  creds = neptune_parse_creds(storage, job_data)

  output_location = job_data["@output"]
  if output_location.nil?
    return "error: output not specified"
  else
    if Repo.does_file_exist?(output_location, storage, creds)
      # TODO: maybe write to file or have
      # special flag for this?
      return Repo.get_output(output_location, storage, creds)
    else
      return "error: output does not exist"
    end
  end
end

def neptune_get_acl(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  Djinn.log_debug("requesting acl")

  type = job_data["@type"]
  storage = job_data["@storage"]
  creds = neptune_parse_creds(storage, job_data)

  output_location = job_data["@output"]
  if output_location.nil?
    return "error: output not specified"
  else
    if Repo.does_file_exist?(output_location, storage, creds)
      return Repo.get_acl(output_location, storage, creds)
    else
      return "error: output does not exist"
    end
  end
end

def neptune_set_acl(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  Djinn.log_debug("setting acl")

  type = job_data["@type"]
  storage = job_data["@storage"]
  creds = neptune_parse_creds(storage, job_data)

  new_acl = job_data["@acl"]

  if new_acl != "public" and new_acl != "private"
    return "error: new acl is neither public nor private"
  end

  output_location = job_data["@output"]
  if output_location.nil?
    return "error: output not specified"
  else
    if Repo.does_file_exist?(output_location, storage, creds)
      return Repo.set_acl(output_location, new_acl, storage, creds)
    else
      return "error: output does not exist"
    end
  end
end

def neptune_compile_code(job_data, secret)
  message = validate_environment(job_data, secret)
  return message unless message == "no error"

  Djinn.log_debug("compiling code")

  main_file = job_data["@main"]
  input_loc = job_data["@code"]
  target = job_data["@target"]

  compiled_dir = "/tmp/compiled-#{HelperFunctions.get_random_alphanumeric}"

  Thread.new {
    makefile = input_loc + "/Makefile"
    makefile2 = input_loc + "/makefile"
    if !(File.exists?(makefile) or File.exists?(makefile2))
      HelperFunctions.generate_makefile(main_file, input_loc)
    end

    compile_cmd = "cd #{input_loc}; make #{target} 2>compile_err 1>compile_out"

    Djinn.log_debug("compiling code by running [#{compile_cmd}]")

    result = `#{compile_cmd}`
    Djinn.log_run("cp -r #{input_loc} #{compiled_dir}")

  }

  return compiled_dir  
end

private

def can_run_job(job_data)
  # no input / output for appscale jobs
  return :ok if job_data["@type"] == "appscale"

  storage = job_data["@storage"]
  creds = neptune_parse_creds(storage, job_data)

  if !ALLOWED_STORAGE_TYPES.include?(storage)
    return "error: bad storage type - supported types are #{ALLOWED_STORAGE_TYPES.join(', ')}"
  end

  if !Repo.valid_storage_creds(storage, creds)
    return "error: bad credentials for accessing storage"
  end

  input_location = job_data["@input"]
  if input_location and !NO_INPUT_NEEDED.include?(job_data['@type'])
    input_exists = Repo.does_file_exist?(input_location, storage, creds)
    Djinn.log_debug("input specified - did #{input_location} exist? #{input_exists}")
    unless input_exists
      return "error: input specified but did not exist"
    end
  else
    Djinn.log_debug("input not specified - moving on")
  end

  output_location = job_data["@output"]
  output_exists = Repo.does_file_exist?(output_location, storage, creds)
  Djinn.log_debug("output specified - did #{output_location} exist? #{output_exists}")
  if output_exists
    return "error: output already exists"
  end

  Djinn.log_debug("job type is [#{job_data["@type"]}]")

  if NO_NODES_NEEDED.include?(job_data["@type"])
    return :ok
  else
    unless job_data["@nodes_to_use"]
      return "error: failed to specify nodes_to_use, a required parameter"
    end
  end

  #if is_hybrid_cloud?
  #  if job_data["@nodes_to_use"].class == Array # request for hybrid cloud
  #    job_data["@nodes_to_use"] = Hash[*job_data["@nodes_to_use"]]
  #  else
  #    return "error: must specify hybrid nodes to use in hybrid cloud runs"
  #  end
  #
  #  # make sure that we have enough clouds available as the user has spec'd
  #end

  if !(is_cloud? or is_hybrid_cloud?)
    Djinn.log_debug("not in cloud")
    # make sure we have enough open nodes
    # a bit race-y, see the TODO on set for more info

    if job_data["@nodes_to_use"].class == Array
      return "error: cannot specify hybrid deployment in non-hybrid cloud runs"
    end

    num_of_vms_needed = Integer(job_data["@nodes_to_use"])

    nodes_to_use = []
      @nodes.each { |node|
        if node.is_open?
          nodes_to_use << node
          break if nodes_to_use.length == num_of_vms_needed
        end
      } 

    if nodes_to_use.length < num_of_vms_needed   
      return "error: not enough free nodes (requested = #{num_of_vms_needed}, available = #{nodes_to_use.length})"
    end
  end

  return :ok
end

def start_job(nodes, job_data)
  Djinn.log_debug("job - start")

  master_role, slave_role = get_node_roles(job_data)

  other_nodes = nodes - [nodes.first]
  add_roles_and_wait(other_nodes, slave_role)
  if !other_nodes.nil? and !other_nodes.empty? # TODO: prettify me
  other_nodes.each { |node|
    node.add_roles(slave_role)
  }
  end

  master_node = nodes.first
  master_node_ip = master_node.private_ip
  master_node.add_roles(master_role)

  master_acc = AppControllerClient.new(master_node_ip, HelperFunctions.get_secret)
  master_acc.add_role(master_role)
end

def get_node_roles(job_data)
  job_type = job_data["@type"]

  if job_type == "appscale"
    component_to_add = job_data["@add_component"]
    master_role = component_to_add
    slave_roles = component_to_add
  elsif job_type == "mapreduce"
    master_role = "db_slave:mapreduce_master"
    slave_roles = "db_slave:mapreduce_slave"
  else
    master_role = "#{job_type}_master"
    slave_roles = "#{job_type}_slave"
  end

  return master_role, slave_roles
end

def run_job_on_master(master_node, nodes_to_use, job_data)
  Djinn.log_debug("run job on master")
  converted_nodes = Djinn.convert_location_class_to_array(nodes_to_use)

  master_node_ip = master_node.private_ip
  master_acc = AppControllerClient.new(master_node_ip, HelperFunctions.get_secret)

  result = master_acc.run_neptune_job(converted_nodes, job_data)
  Djinn.log_debug("run job result was #{result}")

  loop {
    shadow = get_shadow
    lock_file = get_lock_file_path(job_data)
    command = "ls #{lock_file}; echo $?"
    Djinn.log_debug("shadow's ssh key is #{shadow.ssh_key}")
    job_is_running = `ssh -i #{shadow.ssh_key} -o StrictHostkeyChecking=no root@#{shadow.private_ip} '#{command}'`
    Djinn.log_debug("is job running? [#{job_is_running}]")
    if job_is_running.length > 1
      return_val = job_is_running[-2].chr
      Djinn.log_debug("return val for file #{lock_file} is #{return_val}")
      break if return_val != "0"
    end
    sleep(30)
  }
end

def stop_job(nodes, job_data)
  Djinn.log_debug("job - stop")

  master_role, slave_role = get_node_roles(job_data)

  master_node = nodes.first
  master_node_ip = master_node.private_ip
  master_node.remove_roles(master_role)

  master_acc = AppControllerClient.new(master_node_ip, HelperFunctions.get_secret)
  master_acc.remove_role(master_role)

  other_nodes = nodes - [nodes.first]
  remove_roles(other_nodes, slave_role)
  if !other_nodes.nil? and !other_nodes.empty? # TODO: prettify me
    other_nodes.each { |node|
      node.remove_roles(slave_role)
    }
  end
end

def validate_environment(job_data, secret)
  return BAD_SECRET_MSG unless valid_secret?(secret)
  #return JOB_IN_PROGRESS if lock_file_exists?(job_data)
  return BAD_TYPE_MSG unless NEPTUNE_JOBS.include?(job_data["@type"])

  if job_data["@type"] == "mapreduce"
    return BAD_TABLE_MSG unless DBS_W_HADOOP.include?(@creds["table"])
  end

  return "no error"
end

def lock_file_exists?(job_data)
  return File.exists?(get_lock_file_path(job_data))
end

def touch_lock_file(job_data)
  job_data["@job_id"] = rand(1000000)
  touch_lock_file = "touch #{get_lock_file_path(job_data)}"
  Djinn.log_run(touch_lock_file)
end

def remove_lock_file(job_data)
  shadow = get_shadow
  shadow_ip = shadow.private_ip
  shadow_key = shadow.ssh_key
  done_running = "rm #{get_lock_file_path(job_data)}"

  HelperFunctions.run_remote_command(shadow_ip, done_running, shadow_key, NO_OUTPUT)
end 

def get_lock_file_path(job_data)
  "/tmp/#{job_data['@type']}-#{job_data['@job_id']}-started"
end

def spawn_nodes_for_neptune?(job_data)
  Djinn.log_debug("neptune_info = #{job_data}")
  return !job_data["@nodes_to_use"].nil?
end

def neptune_acquire_nodes(job_data)
  # for jobs where no nodes need to be acquired (e.g., concurrent but not
  # distributed programs), run them on the shadow node
  if NO_NODES_NEEDED.include?(job_data["@type"])
    return [my_node]
  end

  #num_of_vms_needed = optimal_nodes_hill_climbing(job_data, "performance")
  nodes_needed = optimal_nodes(job_data)

  if is_hybrid_cloud?
    Djinn.log_debug("acquiring nodes for hybrid cloud neptune job")

    if nodes_needed.class == Array
      nodes_needed = Hash[nodes_needed]
      Djinn.log_debug("request received to spawn hybrid nodes: #{nodes_needed.inspect}")
    else
      Djinn.log_debug("nodes_needed was not the right class - should have been Array but was #{nodes_needed.class}")
      # TODO: find a way to reject the job here
    end

    nodes_to_use = []

    nodes_needed.each { |cloud, nodes_to_acquire|
      Djinn.log_debug("acquiring #{nodes_to_acquire} nodes for #{cloud}")
      nodes_for_cloud = neptune_find_open_nodes(cloud, nodes_to_acquire, job_data)
      nodes_to_use = [nodes_to_use + nodes_for_cloud].flatten
      # TODO: should check for failures acquiring nodes
    }
  else
    cloud = "cloud1"
    nodes_to_use = neptune_find_open_nodes(cloud, nodes_needed, job_data)
  end

  return nodes_to_use
end

def neptune_find_open_nodes(cloud, nodes_needed, job_data)
  # TODO: assigning nodes -> nodes_to_use should be atomic?
  # or should going through this list be atomic?

  cloud_num = cloud.scan(/cloud(.*)/).flatten.to_s

  nodes_to_use = []
  @nodes.each { |node|
    break if nodes_to_use.length == nodes_needed
    if node.is_open? and node.cloud == cloud
      nodes_to_use << node
    end
  }

  @neptune_nodes = nodes_to_use

  nodes_available = nodes_to_use.length
  new_nodes_needed = nodes_needed - nodes_available
  Djinn.log_debug("need #{nodes_needed} total, currently have #{nodes_available} to spare")

  if is_cloud?
    if new_nodes_needed > 0
      Djinn.log_debug("spawning up #{new_nodes_needed} for neptune job in cloud 1")
      neptune_acquire_nodes_for_cloud(cloud_num, new_nodes_needed, job_data)
    end
  else
    if new_nodes_needed > 0
      Djinn.log_debug("non-cloud deployment and the neptune user has asked for too many nodes")
      # TODO: find a way to reject the job here
    end
  end

  nodes_to_use = []
  @neptune_nodes.each { |node|
    break if nodes_to_use.length == nodes_needed
    if node.is_open? and node.cloud == cloud
      Djinn.log_debug("will use node [#{node}] for computation")
      nodes_to_use << node
    end
  }

  return nodes_to_use
end

def neptune_acquire_nodes_for_cloud(cloud_num, new_vms_needed, job_data)
  return if new_vms_needed < 1
  Djinn.log_debug("spawning up #{new_vms_needed} vms")

  job = "open" # *_helper will add the right role later
  machine = @creds["machine"]
  ENV['EC2_URL'] = @creds["ec2_url"]
  instance_type = @creds["instance_type"]
  keyname = @creds["keyname"]
  infrastructure = @creds["infrastructure"]

  HelperFunctions.set_creds_in_env(@creds, cloud_num)
  new_node_info = HelperFunctions.spawn_vms(new_vms_needed, job, machine,
    instance_type, keyname, infrastructure, "cloud#{cloud_num}")
  new_nodes = Djinn.convert_location_array_to_class(new_node_info, keyname)

  node_start_time = Time.now
  node_end_time = Time.now + NOT_QUITE_AN_HOUR

  new_nodes.each { |node|
    node.set_time_info(node_start_time, node_end_time)
  }

  @nodes.concat(new_nodes)
  @neptune_nodes.concat(new_nodes)

  new_nodes.each { |node|
    initialize_node(node)
    Djinn.log_debug("new node for compute is #{node.serialize}")
  }
  
  Djinn.log_debug("got all the vms i needed!")
end

def neptune_release_nodes(nodes_to_use, job_data)
  if is_hybrid_cloud?
    abort("hybrid cloud mode is definitely not supported")
  elsif is_cloud?
    nodes_to_use.each { |node|
      node.set_roles("open")
    }

    # don't worry about terminating the vms - the appcontroller
    # will take care of this in its heartbeat loop
  else
    return
  end
end

def get_job_name(job_data)
  job_name = job_data["@type"]

  ["@code", "@main", "@map", "@reduce", "@simulations", "@add_component"].each { |item|
    if job_data[item]
      job_name += " - " + "#{job_data[item]}"
    end
  }

  return job_name
end

def add_roles_and_wait(nodes, roles)
  return if nodes.nil?

  nodes.each { |node|
    node.add_roles(roles)
    acc = AppControllerClient.new(node.private_ip, HelperFunctions.get_secret)
    acc.add_role(roles)
    acc.wait_for_node_to_be(roles)
    Djinn.log_debug("[just added] node at #{node.private_ip} is now #{node.jobs.join(', ')}")
  }
end

def remove_roles(nodes, roles)
  return if nodes.nil?

  nodes.each { |node|
    node.remove_roles(roles)
    acc = AppControllerClient.new(node.private_ip, HelperFunctions.get_secret)
    acc.remove_role(roles)
    Djinn.log_debug("[just removed] node at #{node.private_ip} is now #{node.jobs.join(', ')}")
  }
end

def copyFromShadow(location_on_shadow)
  shadow = get_shadow
  shadow_ip = shadow.private_ip
  shadow_key = shadow.ssh_key

  copy_from_shadow = "scp -r -i #{my_node.ssh_key} #{location_on_shadow} root@#{my_node.public_ip}:#{location_on_shadow}"
  HelperFunctions.run_remote_command(shadow_ip, copy_from_shadow, shadow_key, NO_OUTPUT)
end

def optimal_nodes(job_data)
  return job_data["@nodes_to_use"]
end

=begin
Hill Climbing Algorithm
  # find minimum execution time t1
  # find neighbors t0 and t2

  # if t0 is too low set it to t1
  # if t2 is too high set it to t1

  # if no data for either, choose t2
  # if no data for t0, choose t0
  # if data for both, choose t1
=end
def optimal_nodes_hill_climbing(job_data, thing_to_optimize)
  job_name = get_job_name(job_data)

  if thing_to_optimize != "cost" and thing_to_optimize != "performance"
    abort("bad thing to optimize - can be cost or performance but was #{thing_to_optimize}")
  end

  current_data = @neptune_jobs[job_name]
  if current_data.nil? or current_data.empty?
    Djinn.log_debug("neptune - no job data yet for [#{job_name}]")
    return job_data["@nodes_to_use"]
  end

  Djinn.log_debug("found job data for [#{job_name}]")

  min_val = INFINITY
  optimal_job = nil
  current_data.each { |job|
    Djinn.log_debug("current job data is [#{job}]")

    if thing_to_optimize == "performance"
      my_val = job.total_time
    elsif thing_to_optimize == "cost"
      my_val = job.cost
    else
      abort("bad thing to optimize again")
    end

    if my_val < min_val
      Djinn.log_debug("found a new minimum - [#{job}]")
      optimal_job = job
    end
  }

  Djinn.log_debug("minimum is - [#{optimal_job}]")

  search_space = job_data["@can_run_on"]
  t1 = optimal_job.num_nodes

  Djinn.log_debug("optimal right now is t1 = #{t1}")
  t0, t2 = find_neighbors(t1, search_space)
  Djinn.log_debug("t1's neighbors are #{t0} and t2 = #{t2}")

  d0 = get_job_data(job_name, t0)
  d2 = get_job_data(job_name, t2)

  return t2 if d0.nil? and d2.nil?
  return t0 if d0.nil?
  return t1
end

def find_neighbors(val, search_space)
  abort("no empty arrays") if search_space.nil? or search_space.empty?

  left, right = nil, nil
  length = search_space.length
  search_space.each_with_index { |item, index|
    # set left
    if index <= 0
      left = val
    else
      left = search_space[index-1]
    end

    # set right
    if index < length - 1
      right = search_space[index+1]
    else
      right = val
    end

    break if item == val
  }

  return left, right
end

def get_job_data(job_name, time)
  relevant_jobs = @neptune_jobs[job_name]
  relevant_jobs.each { |job|
    return job if job.total_time == time
  }

  return nil
end

def neptune_write_job_output(job_data, output_location)
  neptune_write_job_output_handler(job_data, output_location, is_file=true)
end

def neptune_write_job_output_str(job_data, string)
  neptune_write_job_output_handler(job_data, string, is_file=false)
end

def neptune_write_job_output_handler(job_data, output, is_file)
  db_location = job_data["@output"]
  storage = job_data["@storage"]
  creds = neptune_parse_creds(storage, job_data)

  job_type = job_data["@type"]
  Djinn.log_debug("[#{job_type}] job done - writing output to #{db_location}")
  Repo.set_output(db_location, output, storage, creds, is_file)
end

def neptune_parse_creds(storage, job_data)
  creds = {}

  if storage == "s3"
    ['EC2_ACCESS_KEY', 'EC2_SECRET_KEY', 'S3_URL'].each { |item|
      creds[item] = job_data["@#{item}"]
    }
  end

  return creds
end

def neptune_get_seed_vals(num_vals)
  random_numbers = []
  num_vals.times {
    loop {
      possible_rand = rand(10000)
      unless random_numbers.include?(possible_rand)
        random_numbers << possible_rand
        break
      end
    }
  }

  return random_numbers
end

def neptune_uncompress_file(tar)
  unless File.exists?(tar)
    abort("The file #{tar} didn't exist, so we couldn't uncompress it.")
  end

  if tar.scan(/.tar.gz\Z/)
    dir = File.dirname(tar)
    Djinn.log_run("cd #{dir}; tar zxvf #{tar}")
    return
  end

  # TODO: add other extension types: zip, bzip2, tar, gz
  #ext = File.extname(tar)
  #
  #case ext
  #when "."
  #end
end

