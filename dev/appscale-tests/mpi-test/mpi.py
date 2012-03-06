from google.appengine.api import neptune



# Input job
input_job = """neptune (
  :type => "input"
  :local => "/home/dceresuela/PFC/pfc/dev/mpi-test/mpi"
  :remote => "/mpi"
)"""

# MPI job
mpi_job = """neptune (
  :type => "mpi",
  :code => "/mpi",
  :nodes_to_use => 2,
  :output => "/mpi-output.txt"
)"""


# Output job
output_job = """output = neptune (
  :type => "output"
  :output => "/mpi-output.txt"
)"""




if can_run_jobs():
  print "Creating files...'
  input_file = write_neptune_job_code(input_job)
  mpi_file = write_neptune_job_code(mpi_job)
  output_file = write_neptune_job_code(output_job)
  print "Files created'
  print "Running jobs...'
  run_neptune_job_code(input_file)
  run_neptune_job_code(mpi_file)
  run_neptune_job_code(output_file)
  print "Jobs run"
  
else:
  print "You can't run jobs'
