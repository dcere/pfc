#!/usr/bin/ruby
# Programmer: Chris Bunch (cgb@cs.ucsb.edu)

require 'app_controller_client'
require 'common_functions'

# Setting verbose to nil here suppresses the otherwise
# excessive SSL cert warning messages that will pollute
# stderr and worry users unnecessarily.
$VERBOSE = nil

#MPI_RUN_JOB_REQUIRED = %w{ input output code filesystem }
#MPI_REQUIRED = %w{ output }
#X10_RUN_JOB_REQUIRED = %w{ input output code filesystem }
#X10_REQUIRED = %w{ output }
#DFSP_RUN_JOB_REQUIRED = %w{ output simulations }
#DFSP_REQUIRED = %w{ output }
#CEWSSA_RUN_JOB_REQUIRED = %w{ output simulations }
#CEWSSA_REQUIRED = %w{ output }
#MR_RUN_JOB_REQUIRED = %w{ }
#MR_REQUIRED = %w{ output }

# A list of Neptune jobs that do not require nodes to be spawned
# up for computation
NO_NODES_NEEDED = ["acl", "input", "output", "compile"]

# A list of Neptune jobs that do not require the output to be
# specified beforehand
NO_OUTPUT_NEEDED = ["input"]

# A list of storage mechanisms that we can use to store and retrieve
# data to for Neptune jobs.
ALLOWED_STORAGE_TYPES = ["appdb", "gstorage", "s3", "walrus"]

# A list of jobs that require some kind of work to be done before
# the actual computation can be performed.
NEED_PREPROCESSING = ["compile", "erlang", "mpi", "ssa"]

# A set of methods and constants that we've monkey-patched to enable Neptune
# support. In the future, it is likely that the only exposed / monkey-patched
# method should be job, while the others could probably be folded into either
# a Neptune-specific class or into CommonFunctions.
# TODO(cbunch): This doesn't look like it does anything - run the integration
# test and confirm one way or the other.
class Object
end

# Certain types of jobs need steps to be taken before they
# can be started (e.g., copying input data or code over).
# This method dispatches the right method to use based
# on the type of the job that the user has asked to run.
def do_preprocessing(job_data)
  job_type = job_data["@type"]
  if !NEED_PREPROCESSING.include?(job_type)
    return
  end

  preprocess = "preprocess_#{job_type}".to_sym
  send(preprocess, job_data)
end

# This preprocessing method copies over the user's code to the
# Shadow node so that it can be compiled there. A future version
# of this method may also copy over libraries as well.
def preprocess_compile(job_data, shell=Kernel.method(:`))
  code = File.expand_path(job_data["@code"])
  if !File.exists?(code)
    abort("The source file #{code} does not exist.")
  end

  suffix = code.split('/')[-1]
  dest = "/tmp/#{suffix}"
  keyname = job_data["@keyname"]
  shadow_ip = CommonFunctions.get_from_yaml(keyname, :shadow)

  ssh_args = "-i ~/.appscale/#{keyname}.key -o StrictHostkeyChecking=no root@#{shadow_ip}"
  remove_dir = "ssh #{ssh_args} 'rm -rf #{dest}' 2>&1"
  puts remove_dir
  shell.call(remove_dir)

  CommonFunctions.scp_to_shadow(code, dest, keyname, is_dir=true)

  job_data["@code"] = dest
end

def preprocess_erlang(job_data, file=File, common_functions=CommonFunctions)
  if !job_data["@code"]
    abort("When running Erlang jobs, :code must be specified.")
  end

  source_code = file.expand_path(job_data["@code"])
  if !file.exists?(source_code)
    abort("The specified code, #{job_data['@code']}," +
      " didn't exist. Please specify one that exists and try again")
  end
  dest_code = "/tmp/"

  keyname = job_data["@keyname"]
  common_functions.scp_to_shadow(source_code, dest_code, keyname)
end

# This preprocessing method verifies that the user specified the number of nodes
# to use. If they also specified the number of processes to use, we also verify
# that this value is at least as many as the number of nodes (that is, nodes
# can't be underprovisioned in MPI).
def preprocess_mpi(job_data)
  if !job_data["@nodes_to_use"]
    abort("When running MPI jobs, :nodes_to_use must be specified.")
  end

  if !job_data["@procs_to_use"]
    abort("When running MPI jobs, :procs_to_use must be specified.")
  end

  if job_data["@procs_to_use"]
    p = job_data["@procs_to_use"]
    n = job_data["@nodes_to_use"]
    if p < n
      abort("When specifying both :procs_to_use and :nodes_to_use" +
        ", :procs_to_use must be at least as large as :nodes_to_use. Please " +
        "change this and try again. You specified :procs_to_use = #{p} and" +
        ":nodes_to_use = #{n}.")
    end
  end

  if job_data["@argv"]
    argv = job_data["@argv"]
    if argv.class != String and argv.class != Array
      abort("The value specified for :argv must be either a String or Array") 
    end

    if argv.class == Array
      job_data["@argv"] = argv.join(' ')
    end
  end

  return job_data
end

# This preprocessing method verifies that the user specified the number of
# trajectories to run, via either :trajectories or :simulations. Both should
# not be specified - only one or the other, and regardless of which they
# specify, convert it to be :trajectories.
def preprocess_ssa(job_data)
  if job_data["@simulations"] and job_data["@trajectories"]
    abort("Both :simulations and :trajectories cannot be specified - use one" +
      " or the other.")
  end

  if job_data["@simulations"]
    job_data["@trajectories"] = job_data["@simulations"]
    job_data.delete("@simulations")
  end

  if !job_data["@trajectories"]
    abort(":trajectories needs to be specified when running ssa jobs")
  end

  return job_data
end

def get_job_data(params)
  job_data = {}
  params.each { |k, v|
    key = "@#{k}"
    job_data[key] = v
  }

  job_data.delete("@job")
  job_data["@keyname"] = params[:keyname] || "appscale"

  job_data["@type"] = job_data["@type"].to_s
  type = job_data["@type"]

  if type == "upc" or type == "x10"
    job_data["@type"] = "mpi"
    type = "mpi"
  end

  # kdt jobs also run as mpi jobs, but need to pass along an executable
  # parameter to let mpiexec know to use python to exec it
  if type == "kdt"
    job_data["@type"] = "mpi"
    type = "mpi"

    job_data["@executable"] = "python"
  end

  if job_data["@nodes_to_use"].class == Hash
    job_data["@nodes_to_use"] = job_data["@nodes_to_use"].to_a.flatten
  end

  if !NO_OUTPUT_NEEDED.include?(type)
    if (job_data["@output"].nil? or job_data["@output"] == "")
      abort("Job output must be specified")
    end

    if job_data["@output"][0].chr != "/"
      abort("Job output must begin with a slash ('/')")
    end
  end

  return job_data
end

def validate_storage_params(job_data)
  if !job_data["@storage"]
    job_data["@storage"] = "appdb"
  end

  storage = job_data["@storage"]
  if !ALLOWED_STORAGE_TYPES.include?(storage)
    abort("Supported storage types are #{ALLOWED_STORAGE_TYPES.join(', ')}" +
      " - we do not support #{storage}.")
  end

  # Our implementation for storing / retrieving via Google Storage
  # and Walrus uses
  # the same library as we do for S3 - so just tell it that it's S3
  if storage == "gstorage" or storage == "walrus"
    storage = "s3"
    job_data["@storage"] = "s3"
  end

  if storage == "s3"
    ["EC2_ACCESS_KEY", "EC2_SECRET_KEY", "S3_URL"].each { |item|
      if job_data["@#{item}"]
        puts "Using specified #{item}"
      else
        if ENV[item]
          puts "Using #{item} from environment"
          job_data["@#{item}"] = ENV[item]
        else
          abort("When storing data to S3, #{item} must be specified or be in " + 
            "your environment. Please do so and try again.")
        end
      end
    }
  end

  return job_data
end

# This method takes a file on the local user's computer and stores it remotely
# via AppScale. It returns a hash map indicating whether or not the job
# succeeded and if it failed, the reason for it.
def get_input(job_data, ssh_args, shadow_ip, controller, file=File,
  shell=Kernel.method(:`))
  result = {:result => :success}

  if !job_data["@local"]
    abort("You failed to specify a file to copy over via the :local flag.")
  end

  local_file = file.expand_path(job_data["@local"])
  if !file.exists?(local_file)
    reason = "the file you specified to copy, #{local_file}, doesn't exist." + 
        " Please specify a file that exists and try again."
    return {:result => :failure, :reason => reason}  
  end

  remote = "/tmp/neptune-input-#{rand(100000)}"
  scp_cmd = "scp -r #{ssh_args} #{local_file} root@#{shadow_ip}:#{remote}"
  puts scp_cmd
  shell.call(scp_cmd)

  job_data["@local"] = remote
  puts "job data = #{job_data.inspect}"
  response = controller.put_input(job_data)
  if response
    return {:result => :success}
  else
    # TODO - expand this to include the reason why it failed
    return {:result => :failure}
  end
end

# This method waits for AppScale to finish compiling the user's code, indicated
# by AppScale copying the finished code to a pre-determined location.
def wait_for_compilation_to_finish(ssh_args, shadow_ip, compiled_location,
  shell=Kernel.method(:`))
  loop {
    ssh_command = "ssh #{ssh_args} root@#{shadow_ip} 'ls #{compiled_location}' 2>&1"
    puts ssh_command
    ssh_result = shell.call(ssh_command)
    puts "result was [#{ssh_result}]"
    if ssh_result =~ /No such file or directory/
      puts "Still waiting for code to be compiled..."
    else
      puts "compilation complete! Copying compiled code to #{copy_to}"
      return
    end
    sleep(5)
  }
end

# This method sends out a request to compile code, waits for it to finish, and
# gets the standard out and error returned from the compilation. This method
# returns a hash containing the standard out, error, and a result that indicates
# whether or not the compilation was successful.
def compile_code(job_data, ssh_args, shadow_ip, shell=Kernel.method(:`))
  compiled_location = controller.compile_code(job_data)

  copy_to = job_data["@copy_to"]

  wait_for_compilation_to_finish(ssh_args, shadow_ip, compiled_location)

  FileUtils.rm_rf(copy_to)

  scp_command = "scp -r #{ssh_args} root@#{shadow_ip}:#{compiled_location} #{copy_to} 2>&1"
  puts scp_command
  shell.call(scp_command)

  code = job_data["@code"]
  dirs = code.split(/\//)
  remote_dir = "/tmp/" + dirs[-1] 

  [remote_dir, compiled_location].each { |remote_files|
    ssh_command = "ssh #{ssh_args} root@#{shadow_ip} 'rm -rf #{remote_files}' 2>&1"
    puts ssh_command
    shell.call(ssh_command)
  }

  return get_std_out_and_err(copy_to)
end

# This method returns a hash containing the standard out and standard error
# from a completed job, as well as a result field that indicates whether or
# not the job completed successfully (success = no errors).
def get_std_out_and_err(location)
  result = {}

  out = File.open("#{location}/compile_out") { |f| f.read.chomp! }
  result[:out] = out

  err = File.open("#{location}/compile_err") { |f| f.read.chomp! }
  result[:err] = err

  if result[:err]
    result[:result] = :failure
  else
    result[:result] = :success
  end    

  return result
end

def upload_app_for_cicero(job_data)
  if !job_data["@app"]
    puts "No app specified, not uploading..." 
    return
  end

  app_location = File.expand_path(job_data["@app"])
  if !File.exists?(app_location)
    abort("The app you specified, #{app_location}, does not exist." + 
      "Please specify one that does and try again.")
  end

  keyname = job_data["@keyname"] || "appscale"
  if job_data["@appscale_tools"]
    upload_app = File.expand_path(job_data["@appscale_tools"]) +
      File::SEPARATOR + "bin" + File::SEPARATOR + "appscale-upload-app"
  else
    upload_app = "appscale-upload-app"
  end

  puts "Uploading AppEngine app at #{app_location}"
  upload_command = "#{upload_app} --file #{app_location} --test --keyname #{keyname}"
  puts upload_command
  puts `#{upload_command}`
end

# This method actually runs the Neptune job, given information about the job
# as well as information about the node to send the request to.
def run_job(job_data, ssh_args, shadow_ip, secret,
  controller=AppControllerClient, file=File)
  controller = controller.new(shadow_ip, secret)

  # TODO - right now the job is assumed to succeed in many cases
  # need to investigate the various failure scenarios
  result = { :result => :success }

  case job_data["@type"]
  when "input"
    result = get_input(job_data, ssh_args, shadow_ip, controller, file)
  when "output"
    result[:output] = controller.get_output(job_data)
  when "get-acl"
    job_data["@type"] = "acl"
    result[:acl] = controller.get_acl(job_data)
  when "set-acl"
    job_data["@type"] = "acl"
    result[:acl] = controller.set_acl(job_data)
  when "compile"
    result = compile_code(job_data, ssh_args, shadow_ip)
  when "cicero"
    upload_app_for_cicero(job_data)
    msg = controller.start_neptune_job(job_data)
    result[:msg] = msg
    result[:result] = :failure if result[:msg] !~ /job is now running\Z/
  else
    msg = controller.start_neptune_job(job_data)
    result[:msg] = msg
    result[:result] = :failure if result[:msg] !~ /job is now running\Z/
  end

  return result
end

# This method is the heart of Neptune - here, we take
# blocks of code that the user has written and convert them
# into HPC job requests. At a high level, the user can
# request to run a job, retrieve a job's output, or
# modify the access policy (ACL) for the output of a
# job. By default, job data is private, but a Neptune
# job can be used to set it to public later (and
# vice-versa).
def neptune(params)
  puts "Received a request to run a job."
  puts params[:type]

  job_data = get_job_data(params)
  validate_storage_params(job_data)
  puts "job data = #{job_data.inspect}"
  do_preprocessing(job_data) 
  keyname = job_data["@keyname"]

  shadow_ip = CommonFunctions.get_from_yaml(keyname, :shadow)
  secret = CommonFunctions.get_secret_key(keyname)
  ssh_key = File.expand_path("~/.appscale/#{keyname}.key")
  ssh_args = "-i ~/.appscale/#{keyname}.key -o StrictHostkeyChecking=no "

  return run_job(job_data, ssh_args, shadow_ip, secret)
end
