#!/usr/bin/ruby
# Programmer: Chris Bunch
# baz

require 'djinn'

public 

def neptune_go_run_job(nodes, job_data, secret)
  return BAD_SECRET_MSG unless valid_secret?(secret)
  Djinn.log_debug("go - run")

  Thread.new {
    keyname = @creds['keyname']
    nodes = Djinn.convert_location_array_to_class(nodes, keyname)

    #ENV['HOME'] = "/root"
    Djinn.log_debug("job data is #{job_data.inspect}")

    code = job_data['@code'].split(/\//)[-1]

    code_dir = "/tmp/go-#{rand()}/"
    code_loc = "#{code_dir}/#{code}"
    output_loc = "#{code_dir}/output.txt"
    FileUtils.mkdir_p(code_dir)

    remote = job_data['@code']
    storage = job_data['@storage']
    creds = neptune_parse_creds(storage, job_data)

    Repo.get_output(remote, storage, creds, "#{code_loc}")

    Djinn.log_debug("got code #{code}, saved at #{code_loc}")
    Djinn.log_run("chmod +x #{code_loc}")
    Djinn.log_run("cd #{code_dir}; ./#{code} > #{output_loc}")

    Repo.set_output(job_data["@output"], output_loc, storage, creds, IS_FILE)

    remove_lock_file(job_data)

    #Djinn.log_run("rm -rfv #{code_dir}")
  }

  return "OK"
end

private

def start_go_master()
  Djinn.log_debug("#{my_node.private_ip} is starting go master")
end

def start_go_slave()
  Djinn.log_debug("#{my_node.private_ip} is starting go slave")
end

def stop_go_master()
  Djinn.log_debug("#{my_node.private_ip} is stopping go master")
end

def stop_go_slave()
  Djinn.log_debug("#{my_node.private_ip} is stopping go slave")
end

